#!/usr/bin/env python3
"""Remove the project-level local Swift package reference from a generated pbxproj.

Xcode 16+ refuses to resolve a local package that is an ancestor of the .xcodeproj
(it shows a stuck "?" under Package Dependencies). The PencilNotes app instead gets
the engine from the repo-root PencilNotes.xcworkspace, where the package is a
workspace member, and the app target links the products by name. For that to work
the generated project must NOT carry XcodeGen's ancestor XCLocalSwiftPackageReference
— this script strips it (and the cosmetic "Packages" folder group) while keeping the
target's packageProductDependencies intact.

Usage: strip_local_package_ref.py path/to/Project.xcodeproj/project.pbxproj
"""
import re
import sys


def strip(text: str) -> str:
    # 1) Drop the whole XCLocalSwiftPackageReference section.
    text = re.sub(
        r"/\* Begin XCLocalSwiftPackageReference section \*/.*?"
        r"/\* End XCLocalSwiftPackageReference section \*/\n",
        "",
        text,
        flags=re.DOTALL,
    )

    # 2) Drop any child line that points at an XCLocalSwiftPackageReference
    #    (the entry inside the PBXProject `packageReferences = ( ... );`).
    text = re.sub(r"^\s*[0-9A-F]{24} /\* XCLocalSwiftPackageReference .*\*/,\n", "", text, flags=re.MULTILINE)

    # 3) Collapse a now-empty packageReferences array.
    text = re.sub(r"\t*packageReferences = \(\s*\);\n", "", text)

    # 4) Drop the local-package folder PBXFileReference (folder under SOURCE_ROOT).
    text = re.sub(
        r"^\s*[0-9A-F]{24} /\* .*? \*/ = \{isa = PBXFileReference; lastKnownFileType = folder; "
        r"name = .*?; path = .*?; sourceTree = SOURCE_ROOT; \};\n",
        "",
        text,
        flags=re.MULTILINE,
    )

    # 5) Drop the cosmetic "Packages" PBXGroup and the child line referencing it.
    text = re.sub(
        r"^\s*[0-9A-F]{24} /\* Packages \*/ = \{\n"
        r"(?:.*\n)*?\t*\};\n",
        "",
        text,
        flags=re.MULTILINE,
    )
    text = re.sub(r"^\s*[0-9A-F]{24} /\* Packages \*/,\n", "", text, flags=re.MULTILINE)

    return text


def main() -> int:
    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        original = f.read()
    stripped = strip(original)
    with open(path, "w", encoding="utf-8") as f:
        f.write(stripped)
    removed = original.count("XCLocalSwiftPackageReference") - stripped.count("XCLocalSwiftPackageReference")
    print(f"stripped {removed} XCLocalSwiftPackageReference occurrence(s) from {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
