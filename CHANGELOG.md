## [Unreleased]

## 0.1.6

- Remove premature error checking from Cutlass.default_buildpack_paths

## 0.1.5

- Expect build.sh scripts to produce a directory named "target" https://github.com/heroku/cutlass/pull/7

## 0.1.4

- Cutlass.default_buildpack_paths= now accepts a LocalBuildpack https://github.com/heroku/cutlass/pull/6

## 0.1.3

- Do not connect to docker if it's not needed https://github.com/heroku/cutlass/pull/5

## 0.1.2

- App.new accepts a buildpack array with the `:default` symbol which acts as a shortcut for `Cutlass.default_buildpack_paths` https://github.com/heroku/cutlass/pull/4
- `Cutlass.default_buildpack_paths=` raises an error if you pass in a path that does not exist. https://github.com/heroku/cutlass/pull/4

## 0.1.1

- Fix App#pack_build with no block https://github.com/heroku/cutlass/pull/3

## [0.1.0] - 2021-03-29

- Initial release
