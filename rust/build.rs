use std::env;
use std::path::{Path, PathBuf};

fn main() {
    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();
    let lib_path = match target_os.as_str() {
        "linux" => "../lib/x86_64-unkown-linux",
        "android" => "../lib/aarch64-linux-android",
        _ => todo!(),
    };
    let has_linked = link_library("wavify_core", lib_path);
    if !has_linked {
        panic!("Linking dynamic library failed")
    }
}

fn link_library<T: std::fmt::Display>(name: T, search_path: &str) -> bool {
    let libname = format!("lib{name}.so");
    if let Some(p) = find_library(&libname, search_path) {
        println!("cargo:rustc-link-search={}", p.display());
        println!("cargo:rustc-link-lib={name}");
        return true;
    }
    false
}

fn find_library<T: AsRef<Path>>(name: T, search_path: &str) -> Option<PathBuf> {
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
