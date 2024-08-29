import Buffer "mo:base/Buffer";

module ArrayUtils {
    /// Append two arrays efficiently using a buffer
    public func appendArray<T>(array1 : [T], array2 : [T]) : [T] {
        let buffer = Buffer.fromArray<T>(array1);
        buffer.append(Buffer.fromArray<T>(array2));
        Buffer.toArray(buffer);
    };

    /// Push an element to the end of an array
    public func pushToArray<T>(element : T, array : [T]) : [T] {
        let buffer = Buffer.fromArray<T>(array);
        buffer.add(element);
        Buffer.toArray(buffer);
    };

};
