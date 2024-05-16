use std::env;
use std::fs;
use std::path::{Path, PathBuf};

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
        _ => todo!(),
    };

    let lib_dir = dep_dir.join(lib_subdir);
    let lib_out_dir = out_dir.join("lib/").join(lib_subdir);
    copy_dir(&lib_dir, &lib_out_dir).unwrap();

    let has_linked = link_library("wavify_core", &lib_out_dir);
    if !has_linked {
        panic!("Linking dynamic library failed")
    }

    let has_linked_tflitec = link_library("tensorflowlite_c", &lib_out_dir);
    if !has_linked_tflitec {
        panic!("Linking tflitec failed")
    }
}

fn link_library<T: std::fmt::Display>(name: T, search_path: &PathBuf) -> bool {
    let libname = format!("lib{name}.so");
    if let Some(p) = find_library(&libname, search_path) {
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

fn copy_dir<U: AsRef<Path>, V: AsRef<Path>>(from: U, to: V) -> Result<(), std::io::Error> {
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
