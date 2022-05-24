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
import Foundation

#if canImport(Glibc)
import Glibc
private let _exit: (Int32) -> Never = Glibc.exit
#elseif canImport(Darwin)
import Darwin
private let _exit: (Int32) -> Never = Darwin.exit
#elseif canImport(CRT)
import CRT
private let _exit: (Int32) -> Never = ucrt._exit
#elseif canImport(WASILibc)
import WASILibc
#endif

Task {
    do {
        let cli = try FairTool()
        try await cli.runCLI()
        _exit(0)
    } catch {
        print("fairtool error: \(error.localizedDescription)")
        error.dumpError()
        _exit(.init((error as NSError).code))
    }
}

RunLoop.main.run()
