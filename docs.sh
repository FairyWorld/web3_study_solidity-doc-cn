#!/usr/bin/env bash

#------------------------------------------------------------------------------
# Bash script to build the Solidity Sphinx documentation locally.
#
# The documentation for solidity is hosted at:
#
#     https://docs.soliditylang.org
#
# ------------------------------------------------------------------------------
# This file is part of solidity.
#
# solidity is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# solidity is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with solidity.  If not, see <http://www.gnu.org/licenses/>
#
# (c) 2016 solidity contributors.
#------------------------------------------------------------------------------

set -euo pipefail

script_dir="$(dirname "$0")"

cd "${script_dir}"
# TODO `--ignore-installed` now fixes an issue where pip tries to uninstall a Debian installed package, but is unable to
# TODO since Debian has decided to not use the RECORD file, which then breaks pip.
# TODO https://github.com/pypa/pip/issues/11631 and https://bugs.launchpad.net/ubuntu/+source/wheel/+bug/2063151
pip3 install -r requirements.txt --ignore-installed --upgrade --upgrade-strategy eager
sphinx-build -n -b html -d _build/doctrees . _build/html
