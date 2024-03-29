# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [7.0.0]
### Breaking changes
- Support Puppet >= 6.1.0
### Added
- Added secure_path parameter (#270)
- Added package_provider parameter (#241)
- Added wheel_config parameter (#271)
- Added support for Manjarolinux (#244)
- Template for RHEL 8 added (#247)
- Added suffix parameter (#248)
### Changed
- Migrated to Github Actions
- Replaced travis-ci badge with Github Actions badge
- Bumped stdlib dependency to < 8.0.0
### Fixed
- sudoversion fact should not run on Windows (#259)
- docs: `ignore` parameter has been renamed to `purge_ignore`
- Removed extra % in sudo::allow template (#242)
- Fixed AIX default package source (#240)

## [6.0.0]
### Breaking changes
- Remove sudo::configs, move hiera lookups to init.pp (#228)
### Fixed
- Do not ensure package, when it's undefined (#213)
- Fix regex matching rhel 5.1 to 5.4 only (#217)
- Add systemctl commands back to SERVICES alias (#224, #225)
### Added
- Add Puppet 6 to travis checks
- Allow usage of sudoreplay (#231)
### Changed
- Let $purge_ignore accept an array of strings (#211)
- Update Puppet version requirement to include version 6 (#230, #234)
### Removed
- Drop Ruby 2.1 from travis checks
