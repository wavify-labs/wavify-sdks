use std::env;
use std::path::{Path, PathBuf};

fn main() {
    let has_linked = link_library("wavify_core");
    if !has_linked {
        panic!("Linking dynamic library failed")
    }
}

fn link_library<T: std::fmt::Display>(name: T) -> bool {
    let libname = format!("lib{name}.so");
    if let Some(p) = find_library(&libname) {
        println!("cargo:rustc-link-search={}", p.display());
        println!("cargo:rustc-link-lib={name}");
        return true;
    }
    false
}

fn find_library<T: AsRef<Path>>(name: T) -> Option<PathBuf> {
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
