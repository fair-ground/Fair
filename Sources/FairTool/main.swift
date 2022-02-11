/**
 Copyright (c) 2022 Marc Prud'hommeaux

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import Swift
import FairApp

#if os(Linux)
import func Glibc.exit
let fairwell = Glibc.exit
#elseif os(Windows)
import func ucrt.exit
let fairwell = ucrt.exit
#elseif canImport(Darwin)
import func Darwin.exit
let fairwell = Darwin.exit
#else
func fairwell(_ code: Int) -> Never { }
#endif

let sema = DispatchSemaphore(value: 0)
Task.detached {
    do {
        try await FairCLI().runCLI()
        sema.signal()
    } catch {
        print("fairtool error: \(error.localizedDescription)")
        error.dumpError()
        fairwell(1)
    }
}

sema.wait()
