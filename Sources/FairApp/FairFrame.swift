/**
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

#if canImport(TabularData)
import TabularData

/// A `DataFrameProtocol` that can filter itself efficiently.
@available(macOS 12.0, iOS 15.0, *)
public protocol FilterableFrame : DataFrameProtocol {
    /// Returns a selection of rows that satisfy a predicate in the columns you select by name.
    /// - Parameters:
    ///   - columnName: The name of a column.
    ///   - type: The type of the column.
    ///   - isIncluded: A predicate closure that receives an element of the column as its argument
    ///   and returns a Boolean that indicates whether the slice includes the element's row.
    /// - Returns: A data frame slice that contains the rows that satisfy the predicate.
    func filter<T>(on columnName: String, _ type: T.Type, _ isIncluded: (T?) throws -> Bool) rethrows -> DataFrame.Slice

    /// Returns a selection of rows that satisfy a predicate in the columns you select by column identifier.
    /// - Parameters:
    ///   - columnID: The identifier of a column in the data frame.
    ///   - isIncluded: A predicate closure that receives an element of the column as its argument
    ///   and returns a Boolean that indicates whether the slice includes the element's row.
    /// - Returns: A data frame slice that contains the rows that satisfy the predicate.
    func filter<T>(on columnID: ColumnID<T>, _ isIncluded: (T?) throws -> Bool) rethrows -> DataFrame.Slice

    /// Generates a data frame that includes the columns you select with a sequence of names.
    /// - Parameter columnNames: A sequence of column names.
    /// - Returns: A new data frame.
    func selecting<S>(columnNames: S) -> Self where S : Sequence, S.Element == String

    /// Generates a data frame that includes the columns you select with a list of names.
    /// - Parameter columnNames: A comma-separated, or variadic, list of column names.
    /// - Returns: A new data frame.
    func selecting(columnNames: String...) -> Self
}

@available(macOS 12.0, iOS 15.0, *)
extension DataFrame : FilterableFrame { }

@available(macOS 12.0, iOS 15.0, *)
extension DataFrame.Slice : FilterableFrame { }
#endif

