#!/usr/bin/env node
/**
 * バージョン自動インクリメントスクリプト (0.0.1刻み)
 * GitHubプッシュ前に `npm run version:bump` で実行し、
 * package.json・Swift側の AppVersion.swift・Xcodeプロジェクト設定の MARKETING_VERSION を同期更新する。
 */

const fs = require("fs");
const path = require("path");

const rootDir = path.resolve(__dirname, "..");
const pkgPath = path.join(rootDir, "package.json");
const swiftVersionPath = path.join(
  rootDir,
  "BangBangBeam",
  "Models",
  "AppVersion.swift"
);
const xcprojPath = path.join(
  rootDir,
  "BangBangBeam.xcodeproj",
  "project.xcproj"
);
const pbxprojPath = path.join(
  rootDir,
  "BangBangBeam.xcodeproj",
  "project.pbxproj"
);

function bumpPatch(version) {
  const parts = version.trim().split(".").map(Number);
  if (parts.length !== 3 || parts.some(isNaN)) {
    throw new Error(`Invalid semantic version: ${version}`);
  }
  parts[2] += 1;
  return `${parts[0]}.${parts[1]}.${parts[2]}`;
}

const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
const oldVersion = pkg.version || "1.0.0";
const newVersion = bumpPatch(oldVersion);

pkg.version = newVersion;
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n", "utf8");

if (fs.existsSync(swiftVersionPath)) {
  let swiftContent = fs.readFileSync(swiftVersionPath, "utf8");
  swiftContent = swiftContent.replace(
    /static let current = "[0-9]+\.[0-9]+\.[0-9]+"/,
    `static let current = "${newVersion}"`
  );
  fs.writeFileSync(swiftVersionPath, swiftContent, "utf8");
}

if (fs.existsSync(xcprojPath)) {
  let xcContent = fs.readFileSync(xcprojPath, "utf8");
  const patchNumber = newVersion.split(".")[2] || "1";
  xcContent = xcContent.replace(
    /"CURRENT_PROJECT_VERSION":\s*"[^"]+"/,
    `"CURRENT_PROJECT_VERSION": "${patchNumber}"`
  );
  xcContent = xcContent.replace(
    /"MARKETING_VERSION":\s*"[^"]+"/,
    `"MARKETING_VERSION": "${newVersion}"`
  );
  fs.writeFileSync(xcprojPath, xcContent, "utf8");
}

if (fs.existsSync(pbxprojPath)) {
  let pbxContent = fs.readFileSync(pbxprojPath, "utf8");
  pbxContent = pbxContent.replace(
    /MARKETING_VERSION = [^;]+;/g,
    `MARKETING_VERSION = ${newVersion};`
  );
  fs.writeFileSync(pbxprojPath, pbxContent, "utf8");
}

console.log(`Version bumped: ${oldVersion} -> ${newVersion}`);
