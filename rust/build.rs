use reqwest::blocking::get;
use std::env;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use tempfile::tempdir;

fn main() {
    let dep_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap())
        .parent()
        .unwrap()
        .join("lib/");
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());

    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();
    let lib_subdir = match target_os.as_str() {
        "linux" => "x86_64-unknown-linux-gnu",
        "android" => "aarch64-linux-android",
        "windows" => "x86_64-pc-windows-gnu",
        "macos" => "aarch64-apple-darwin",
        _ => todo!(),
    };

    let lib_dir = dep_dir.join(lib_subdir);
    let lib_out_dir = out_dir.join("lib/").join(lib_subdir);

    if !lib_dir.exists() {
        // We are limited by crates.io 10MB bundle size
        // hence, we need to download dependencies at build time
        // Note: This is not allowed on docs.rs builds
        // TODO: Enable a mechanism to find dependencies via env vars
        #[cfg(feature = "download-wavify-core")]
        download_and_extract_library(&lib_out_dir).unwrap();
    } else {
        copy_dir(lib_dir, &lib_out_dir).unwrap();
    }

    let has_linked = link_library("wavify_core", &lib_out_dir);
    if !has_linked {
        println!("cargo:warning=Linking wavify core failed")
    }

    let has_linked_tflitec = link_library("tensorflowlite_c", &lib_out_dir);
    if !has_linked_tflitec {
        println!("cargo:warning=Linking tflitec failed")
    }
}

#[cfg(feature = "download-wavify-core")]
fn download_and_extract_library(target: &Path) -> io::Result<()> {
    let base_url = "https://nlkytncvwapfujviszuq.supabase.co/storage/v1/object/public/lib/";
    let target_triplet = match env::var("CARGO_CFG_TARGET_OS").unwrap().as_str() {
        "linux" => "x86_64-unknown-linux-gnu",
        "android" => "aarch64-linux-android",
        "windows" => "x86_64-pc-windows-gnu",
        "macos" => "aarch64-apple-darwin",
        _ => todo!(),
    };
    let filename = target_triplet.to_owned() + ".tar.gz";
    let url = base_url.to_owned() + &filename;

    let temp_dir = tempdir()?;
    let mut response = get(url).unwrap();
    let archive_path = temp_dir.path().join("archive");
    let mut archive_file = fs::File::create(&archive_path)?;
    response.copy_to(&mut archive_file).unwrap();

    let mut ar = tar::Archive::new(flate2::read::GzDecoder::new(fs::File::open(&archive_path)?));
    ar.unpack(temp_dir.path())?;

    let extracted_lib_dir = temp_dir.path().join("lib").join(target_triplet);
    copy_dir(extracted_lib_dir, target)
}

fn link_library<T: std::fmt::Display>(name: T, search_path: &PathBuf) -> bool {
    let libname = if cfg!(target_os = "windows") {
        format!("{name}.dll")
    } else if cfg!(target_os = "macos") {
        format!("lib{name}.dylib")
    } else {
        format!("lib{name}.so")
    };
    if let Some(p) = find_library(libname, search_path) {
        println!("cargo:rustc-link-search={}", p.display());
        println!("cargo:rustc-link-lib={name}");
        return true;
    }
    false
}

fn find_library<T: AsRef<Path>>(name: T, search_path: &PathBuf) -> Option<PathBuf> {
    let maybe_lib_path = PathBuf::from(search_path);
    if maybe_lib_path.exists() {
        return Some(maybe_lib_path);
    }
    if let Ok(p) = env::var("LD_LIBRARY_PATH") {
        if let Some(path) = p
            .split(':')
            .map(Path::new)
            .find(|p| p.join(name.as_ref()).exists())
        {
            return Some(PathBuf::from(path));
        }
    }
    None
}

fn copy_dir<U: AsRef<Path>, V: AsRef<Path>>(from: U, to: V) -> Result<(), io::Error> {
    let mut stack = vec![PathBuf::from(from.as_ref())];

    let output_root = PathBuf::from(to.as_ref());
    let input_root = PathBuf::from(from.as_ref()).components().count();

    while let Some(working_path) = stack.pop() {
        let src: PathBuf = working_path.components().skip(input_root).collect();

        let dest = if src.components().count() == 0 {
            output_root.clone()
        } else {
            output_root.join(&src)
        };

        if fs::metadata(&dest).is_err() {
            fs::create_dir_all(&dest)?;
        }

        for entry in fs::read_dir(working_path)? {
            let entry = entry?;
            let path = entry.path();
            if path.is_dir() {
                stack.push(path);
            } else if let Some(filename) = path.file_name() {
                let dest_path = dest.join(filename);
                fs::copy(&path, &dest_path)?;
            }
        }
    }

    Ok(())
}
