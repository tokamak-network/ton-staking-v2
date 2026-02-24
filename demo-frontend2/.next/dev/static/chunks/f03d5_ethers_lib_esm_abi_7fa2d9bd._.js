(globalThis.TURBOPACK || (globalThis.TURBOPACK = [])).push([typeof document === "object" ? document.currentScript : undefined,
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/bytes32.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "decodeBytes32String",
    ()=>decodeBytes32String,
    "encodeBytes32String",
    ()=>encodeBytes32String
]);
/**
 *  About bytes32 strings...
 *
 *  @_docloc: api/utils:Bytes32 Strings
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/utf8.js [client] (ecmascript)");
;
function encodeBytes32String(text) {
    // Get the bytes
    const bytes = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toUtf8Bytes"])(text);
    // Check we have room for null-termination
    if (bytes.length > 31) {
        throw new Error("bytes32 string must be less than 32 bytes");
    }
    // Zero-pad (implicitly null-terminates)
    return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["zeroPadBytes"])(bytes, 32);
}
function decodeBytes32String(_bytes) {
    const data = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytes"])(_bytes, "bytes");
    // Must be 32 bytes with a null-termination
    if (data.length !== 32) {
        throw new Error("invalid bytes32 - not 32 bytes long");
    }
    if (data[31] !== 0) {
        throw new Error("invalid bytes32 string - no null terminator");
    }
    // Find the null termination
    let length = 31;
    while(data[length - 1] === 0){
        length--;
    }
    // Determine the string value
    return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toUtf8String"])(data.slice(0, length));
} //# sourceMappingURL=bytes32.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "Coder",
    ()=>Coder,
    "Reader",
    ()=>Reader,
    "Result",
    ()=>Result,
    "WordSize",
    ()=>WordSize,
    "Writer",
    ()=>Writer,
    "checkResultErrors",
    ()=>checkResultErrors
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
;
const WordSize = 32;
const Padding = new Uint8Array(WordSize);
// Properties used to immediate pass through to the underlying object
// - `then` is used to detect if an object is a Promise for await
const passProperties = [
    "then"
];
const _guard = {};
const resultNames = new WeakMap();
function getNames(result) {
    return resultNames.get(result);
}
function setNames(result, names) {
    resultNames.set(result, names);
}
function throwError(name, error) {
    const wrapped = new Error(`deferred error during ABI decoding triggered accessing ${name}`);
    wrapped.error = error;
    throw wrapped;
}
function toObject(names, items, deep) {
    if (names.indexOf(null) >= 0) {
        return items.map((item, index)=>{
            if (item instanceof Result) {
                return toObject(getNames(item), item, deep);
            }
            return item;
        });
    }
    return names.reduce((accum, name, index)=>{
        let item = items.getValue(name);
        if (!(name in accum)) {
            if (deep && item instanceof Result) {
                item = toObject(getNames(item), item, deep);
            }
            accum[name] = item;
        }
        return accum;
    }, {});
}
class Result extends Array {
    // No longer used; but cannot be removed as it will remove the
    // #private field from the .d.ts which may break backwards
    // compatibility
    #names;
    /**
     *  @private
     */ constructor(...args){
        // To properly sub-class Array so the other built-in
        // functions work, the constructor has to behave fairly
        // well. So, in the event we are created via fromItems()
        // we build the read-only Result object we want, but on
        // any other input, we use the default constructor
        // constructor(guard: any, items: Array<any>, keys?: Array<null | string>);
        const guard = args[0];
        let items = args[1];
        let names = (args[2] || []).slice();
        let wrap = true;
        if (guard !== _guard) {
            items = args;
            names = [];
            wrap = false;
        }
        // Can't just pass in ...items since an array of length 1
        // is a special case in the super.
        super(items.length);
        items.forEach((item, index)=>{
            this[index] = item;
        });
        // Find all unique keys
        const nameCounts = names.reduce((accum, name)=>{
            if (typeof name === "string") {
                accum.set(name, (accum.get(name) || 0) + 1);
            }
            return accum;
        }, new Map());
        // Remove any key thats not unique
        setNames(this, Object.freeze(items.map((item, index)=>{
            const name = names[index];
            if (name != null && nameCounts.get(name) === 1) {
                return name;
            }
            return null;
        })));
        // Dummy operations to prevent TypeScript from complaining
        this.#names = [];
        if (this.#names == null) {
            void this.#names;
        }
        if (!wrap) {
            return;
        }
        // A wrapped Result is immutable
        Object.freeze(this);
        // Proxy indices and names so we can trap deferred errors
        const proxy = new Proxy(this, {
            get: (target, prop, receiver)=>{
                if (typeof prop === "string") {
                    // Index accessor
                    if (prop.match(/^[0-9]+$/)) {
                        const index = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(prop, "%index");
                        if (index < 0 || index >= this.length) {
                            throw new RangeError("out of result range");
                        }
                        const item = target[index];
                        if (item instanceof Error) {
                            throwError(`index ${index}`, item);
                        }
                        return item;
                    }
                    // Pass important checks (like `then` for Promise) through
                    if (passProperties.indexOf(prop) >= 0) {
                        return Reflect.get(target, prop, receiver);
                    }
                    const value = target[prop];
                    if (value instanceof Function) {
                        // Make sure functions work with private variables
                        // See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy#no_private_property_forwarding
                        return function(...args) {
                            return value.apply(this === receiver ? target : this, args);
                        };
                    } else if (!(prop in target)) {
                        // Possible name accessor
                        return target.getValue.apply(this === receiver ? target : this, [
                            prop
                        ]);
                    }
                }
                return Reflect.get(target, prop, receiver);
            }
        });
        setNames(proxy, getNames(this));
        return proxy;
    }
    /**
     *  Returns the Result as a normal Array. If %%deep%%, any children
     *  which are Result objects are also converted to a normal Array.
     *
     *  This will throw if there are any outstanding deferred
     *  errors.
     */ toArray(deep) {
        const result = [];
        this.forEach((item, index)=>{
            if (item instanceof Error) {
                throwError(`index ${index}`, item);
            }
            if (deep && item instanceof Result) {
                item = item.toArray(deep);
            }
            result.push(item);
        });
        return result;
    }
    /**
     *  Returns the Result as an Object with each name-value pair. If
     *  %%deep%%, any children which are Result objects are also
     *  converted to an Object.
     *
     *  This will throw if any value is unnamed, or if there are
     *  any outstanding deferred errors.
     */ toObject(deep) {
        const names = getNames(this);
        return names.reduce((accum, name, index)=>{
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(name != null, `value at index ${index} unnamed`, "UNSUPPORTED_OPERATION", {
                operation: "toObject()"
            });
            return toObject(names, this, deep);
        }, {});
    }
    /**
     *  @_ignore
     */ slice(start, end) {
        if (start == null) {
            start = 0;
        }
        if (start < 0) {
            start += this.length;
            if (start < 0) {
                start = 0;
            }
        }
        if (end == null) {
            end = this.length;
        }
        if (end < 0) {
            end += this.length;
            if (end < 0) {
                end = 0;
            }
        }
        if (end > this.length) {
            end = this.length;
        }
        const _names = getNames(this);
        const result = [], names = [];
        for(let i = start; i < end; i++){
            result.push(this[i]);
            names.push(_names[i]);
        }
        return new Result(_guard, result, names);
    }
    /**
     *  @_ignore
     */ filter(callback, thisArg) {
        const _names = getNames(this);
        const result = [], names = [];
        for(let i = 0; i < this.length; i++){
            const item = this[i];
            if (item instanceof Error) {
                throwError(`index ${i}`, item);
            }
            if (callback.call(thisArg, item, i, this)) {
                result.push(item);
                names.push(_names[i]);
            }
        }
        return new Result(_guard, result, names);
    }
    /**
     *  @_ignore
     */ map(callback, thisArg) {
        const result = [];
        for(let i = 0; i < this.length; i++){
            const item = this[i];
            if (item instanceof Error) {
                throwError(`index ${i}`, item);
            }
            result.push(callback.call(thisArg, item, i, this));
        }
        return result;
    }
    /**
     *  Returns the value for %%name%%.
     *
     *  Since it is possible to have a key whose name conflicts with
     *  a method on a [[Result]] or its superclass Array, or any
     *  JavaScript keyword, this ensures all named values are still
     *  accessible by name.
     */ getValue(name) {
        const index = getNames(this).indexOf(name);
        if (index === -1) {
            return undefined;
        }
        const value = this[index];
        if (value instanceof Error) {
            throwError(`property ${JSON.stringify(name)}`, value.error);
        }
        return value;
    }
    /**
     *  Creates a new [[Result]] for %%items%% with each entry
     *  also accessible by its corresponding name in %%keys%%.
     */ static fromItems(items, keys) {
        return new Result(_guard, items, keys);
    }
}
function checkResultErrors(result) {
    // Find the first error (if any)
    const errors = [];
    const checkErrors = function(path, object) {
        if (!Array.isArray(object)) {
            return;
        }
        for(let key in object){
            const childPath = path.slice();
            childPath.push(key);
            try {
                checkErrors(childPath, object[key]);
            } catch (error) {
                errors.push({
                    path: childPath,
                    error: error
                });
            }
        }
    };
    checkErrors([], result);
    return errors;
}
function getValue(value) {
    let bytes = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toBeArray"])(value);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(bytes.length <= WordSize, "value out-of-bounds", "BUFFER_OVERRUN", {
        buffer: bytes,
        length: WordSize,
        offset: bytes.length
    });
    if (bytes.length !== WordSize) {
        bytes = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytesCopy"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["concat"])([
            Padding.slice(bytes.length % WordSize),
            bytes
        ]));
    }
    return bytes;
}
class Coder {
    // The coder name:
    //   - address, uint256, tuple, array, etc.
    name;
    // The fully expanded type, including composite types:
    //   - address, uint256, tuple(address,bytes), uint256[3][4][],  etc.
    type;
    // The localName bound in the signature, in this example it is "baz":
    //   - tuple(address foo, uint bar) baz
    localName;
    // Whether this type is dynamic:
    //  - Dynamic: bytes, string, address[], tuple(boolean[]), etc.
    //  - Not Dynamic: address, uint256, boolean[3], tuple(address, uint8)
    dynamic;
    constructor(name, type, localName, dynamic){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            name,
            type,
            localName,
            dynamic
        }, {
            name: "string",
            type: "string",
            localName: "string",
            dynamic: "boolean"
        });
    }
    _throwError(message, value) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, message, this.localName, value);
    }
}
class Writer {
    // An array of WordSize lengthed objects to concatenation
    #data;
    #dataLength;
    constructor(){
        this.#data = [];
        this.#dataLength = 0;
    }
    get data() {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["concat"])(this.#data);
    }
    get length() {
        return this.#dataLength;
    }
    #writeData(data) {
        this.#data.push(data);
        this.#dataLength += data.length;
        return data.length;
    }
    appendWriter(writer) {
        return this.#writeData((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytesCopy"])(writer.data));
    }
    // Arrayish item; pad on the right to *nearest* WordSize
    writeBytes(value) {
        let bytes = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytesCopy"])(value);
        const paddingOffset = bytes.length % WordSize;
        if (paddingOffset) {
            bytes = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytesCopy"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["concat"])([
                bytes,
                Padding.slice(paddingOffset)
            ]));
        }
        return this.#writeData(bytes);
    }
    // Numeric item; pad on the left *to* WordSize
    writeValue(value) {
        return this.#writeData(getValue(value));
    }
    // Inserts a numeric place-holder, returning a callback that can
    // be used to asjust the value later
    writeUpdatableValue() {
        const offset = this.#data.length;
        this.#data.push(Padding);
        this.#dataLength += WordSize;
        return (value)=>{
            this.#data[offset] = getValue(value);
        };
    }
}
class Reader {
    // Allows incomplete unpadded data to be read; otherwise an error
    // is raised if attempting to overrun the buffer. This is required
    // to deal with an old Solidity bug, in which event data for
    // external (not public thoguh) was tightly packed.
    allowLoose;
    #data;
    #offset;
    #bytesRead;
    #parent;
    #maxInflation;
    constructor(data, allowLoose, maxInflation){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            allowLoose: !!allowLoose
        });
        this.#data = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytesCopy"])(data);
        this.#bytesRead = 0;
        this.#parent = null;
        this.#maxInflation = maxInflation != null ? maxInflation : 1024;
        this.#offset = 0;
    }
    get data() {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(this.#data);
    }
    get dataLength() {
        return this.#data.length;
    }
    get consumed() {
        return this.#offset;
    }
    get bytes() {
        return new Uint8Array(this.#data);
    }
    #incrementBytesRead(count) {
        if (this.#parent) {
            return this.#parent.#incrementBytesRead(count);
        }
        this.#bytesRead += count;
        // Check for excessive inflation (see: #4537)
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(this.#maxInflation < 1 || this.#bytesRead <= this.#maxInflation * this.dataLength, `compressed ABI data exceeds inflation ratio of ${this.#maxInflation} ( see: https:/\/github.com/ethers-io/ethers.js/issues/4537 )`, "BUFFER_OVERRUN", {
            buffer: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytesCopy"])(this.#data),
            offset: this.#offset,
            length: count,
            info: {
                bytesRead: this.#bytesRead,
                dataLength: this.dataLength
            }
        });
    }
    #peekBytes(offset, length, loose) {
        let alignedLength = Math.ceil(length / WordSize) * WordSize;
        if (this.#offset + alignedLength > this.#data.length) {
            if (this.allowLoose && loose && this.#offset + length <= this.#data.length) {
                alignedLength = length;
            } else {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "data out-of-bounds", "BUFFER_OVERRUN", {
                    buffer: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytesCopy"])(this.#data),
                    length: this.#data.length,
                    offset: this.#offset + alignedLength
                });
            }
        }
        return this.#data.slice(this.#offset, this.#offset + alignedLength);
    }
    // Create a sub-reader with the same underlying data, but offset
    subReader(offset) {
        const reader = new Reader(this.#data.slice(this.#offset + offset), this.allowLoose, this.#maxInflation);
        reader.#parent = this;
        return reader;
    }
    // Read bytes
    readBytes(length, loose) {
        let bytes = this.#peekBytes(0, length, !!loose);
        this.#incrementBytesRead(length);
        this.#offset += bytes.length;
        // @TODO: Make sure the length..end bytes are all 0?
        return bytes.slice(0, length);
    }
    // Read a numeric values
    readValue() {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toBigInt"])(this.readBytes(WordSize));
    }
    readIndex() {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toNumber"])(this.readBytes(WordSize));
    }
} //# sourceMappingURL=abstract-coder.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/typed.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "Typed",
    ()=>Typed
]);
/**
 *  A Typed object allows a value to have its type explicitly
 *  specified.
 *
 *  For example, in Solidity, the value ``45`` could represent a
 *  ``uint8`` or a ``uint256``. The value ``0x1234`` could represent
 *  a ``bytes2`` or ``bytes``.
 *
 *  Since JavaScript has no meaningful way to explicitly inform any
 *  APIs which what the type is, this allows transparent interoperation
 *  with Soldity.
 *
 *  @_subsection: api/abi:Typed Values
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
;
const _gaurd = {};
function n(value, width) {
    let signed = false;
    if (width < 0) {
        signed = true;
        width *= -1;
    }
    // @TODO: Check range is valid for value
    return new Typed(_gaurd, `${signed ? "" : "u"}int${width}`, value, {
        signed,
        width
    });
}
function b(value, size) {
    // @TODO: Check range is valid for value
    return new Typed(_gaurd, `bytes${size ? size : ""}`, value, {
        size
    });
}
const _typedSymbol = Symbol.for("_ethers_typed");
class Typed {
    /**
     *  The type, as a Solidity-compatible type.
     */ type;
    /**
     *  The actual value.
     */ value;
    #options;
    /**
     *  @_ignore:
     */ _typedSymbol;
    /**
     *  @_ignore:
     */ constructor(gaurd, type, value, options){
        if (options == null) {
            options = null;
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertPrivate"])(_gaurd, gaurd, "Typed");
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            _typedSymbol,
            type,
            value
        });
        this.#options = options;
        // Check the value is valid
        this.format();
    }
    /**
     *  Format the type as a Human-Readable type.
     */ format() {
        if (this.type === "array") {
            throw new Error("");
        } else if (this.type === "dynamicArray") {
            throw new Error("");
        } else if (this.type === "tuple") {
            return `tuple(${this.value.map((v)=>v.format()).join(",")})`;
        }
        return this.type;
    }
    /**
     *  The default value returned by this type.
     */ defaultValue() {
        return 0;
    }
    /**
     *  The minimum value for numeric types.
     */ minValue() {
        return 0;
    }
    /**
     *  The maximum value for numeric types.
     */ maxValue() {
        return 0;
    }
    /**
     *  Returns ``true`` and provides a type guard is this is a [[TypedBigInt]].
     */ isBigInt() {
        return !!this.type.match(/^u?int[0-9]+$/);
    }
    /**
     *  Returns ``true`` and provides a type guard is this is a [[TypedData]].
     */ isData() {
        return this.type.startsWith("bytes");
    }
    /**
     *  Returns ``true`` and provides a type guard is this is a [[TypedString]].
     */ isString() {
        return this.type === "string";
    }
    /**
     *  Returns the tuple name, if this is a tuple. Throws otherwise.
     */ get tupleName() {
        if (this.type !== "tuple") {
            throw TypeError("not a tuple");
        }
        return this.#options;
    }
    // Returns the length of this type as an array
    // - `null` indicates the length is unforced, it could be dynamic
    // - `-1` indicates the length is dynamic
    // - any other value indicates it is a static array and is its length
    /**
     *  Returns the length of the array type or ``-1`` if it is dynamic.
     *
     *  Throws if the type is not an array.
     */ get arrayLength() {
        if (this.type !== "array") {
            throw TypeError("not an array");
        }
        if (this.#options === true) {
            return -1;
        }
        if (this.#options === false) {
            return this.value.length;
        }
        return null;
    }
    /**
     *  Returns a new **Typed** of %%type%% with the %%value%%.
     */ static from(type, value) {
        return new Typed(_gaurd, type, value);
    }
    /**
     *  Return a new ``uint8`` type for %%v%%.
     */ static uint8(v) {
        return n(v, 8);
    }
    /**
     *  Return a new ``uint16`` type for %%v%%.
     */ static uint16(v) {
        return n(v, 16);
    }
    /**
     *  Return a new ``uint24`` type for %%v%%.
     */ static uint24(v) {
        return n(v, 24);
    }
    /**
     *  Return a new ``uint32`` type for %%v%%.
     */ static uint32(v) {
        return n(v, 32);
    }
    /**
     *  Return a new ``uint40`` type for %%v%%.
     */ static uint40(v) {
        return n(v, 40);
    }
    /**
     *  Return a new ``uint48`` type for %%v%%.
     */ static uint48(v) {
        return n(v, 48);
    }
    /**
     *  Return a new ``uint56`` type for %%v%%.
     */ static uint56(v) {
        return n(v, 56);
    }
    /**
     *  Return a new ``uint64`` type for %%v%%.
     */ static uint64(v) {
        return n(v, 64);
    }
    /**
     *  Return a new ``uint72`` type for %%v%%.
     */ static uint72(v) {
        return n(v, 72);
    }
    /**
     *  Return a new ``uint80`` type for %%v%%.
     */ static uint80(v) {
        return n(v, 80);
    }
    /**
     *  Return a new ``uint88`` type for %%v%%.
     */ static uint88(v) {
        return n(v, 88);
    }
    /**
     *  Return a new ``uint96`` type for %%v%%.
     */ static uint96(v) {
        return n(v, 96);
    }
    /**
     *  Return a new ``uint104`` type for %%v%%.
     */ static uint104(v) {
        return n(v, 104);
    }
    /**
     *  Return a new ``uint112`` type for %%v%%.
     */ static uint112(v) {
        return n(v, 112);
    }
    /**
     *  Return a new ``uint120`` type for %%v%%.
     */ static uint120(v) {
        return n(v, 120);
    }
    /**
     *  Return a new ``uint128`` type for %%v%%.
     */ static uint128(v) {
        return n(v, 128);
    }
    /**
     *  Return a new ``uint136`` type for %%v%%.
     */ static uint136(v) {
        return n(v, 136);
    }
    /**
     *  Return a new ``uint144`` type for %%v%%.
     */ static uint144(v) {
        return n(v, 144);
    }
    /**
     *  Return a new ``uint152`` type for %%v%%.
     */ static uint152(v) {
        return n(v, 152);
    }
    /**
     *  Return a new ``uint160`` type for %%v%%.
     */ static uint160(v) {
        return n(v, 160);
    }
    /**
     *  Return a new ``uint168`` type for %%v%%.
     */ static uint168(v) {
        return n(v, 168);
    }
    /**
     *  Return a new ``uint176`` type for %%v%%.
     */ static uint176(v) {
        return n(v, 176);
    }
    /**
     *  Return a new ``uint184`` type for %%v%%.
     */ static uint184(v) {
        return n(v, 184);
    }
    /**
     *  Return a new ``uint192`` type for %%v%%.
     */ static uint192(v) {
        return n(v, 192);
    }
    /**
     *  Return a new ``uint200`` type for %%v%%.
     */ static uint200(v) {
        return n(v, 200);
    }
    /**
     *  Return a new ``uint208`` type for %%v%%.
     */ static uint208(v) {
        return n(v, 208);
    }
    /**
     *  Return a new ``uint216`` type for %%v%%.
     */ static uint216(v) {
        return n(v, 216);
    }
    /**
     *  Return a new ``uint224`` type for %%v%%.
     */ static uint224(v) {
        return n(v, 224);
    }
    /**
     *  Return a new ``uint232`` type for %%v%%.
     */ static uint232(v) {
        return n(v, 232);
    }
    /**
     *  Return a new ``uint240`` type for %%v%%.
     */ static uint240(v) {
        return n(v, 240);
    }
    /**
     *  Return a new ``uint248`` type for %%v%%.
     */ static uint248(v) {
        return n(v, 248);
    }
    /**
     *  Return a new ``uint256`` type for %%v%%.
     */ static uint256(v) {
        return n(v, 256);
    }
    /**
     *  Return a new ``uint256`` type for %%v%%.
     */ static uint(v) {
        return n(v, 256);
    }
    /**
     *  Return a new ``int8`` type for %%v%%.
     */ static int8(v) {
        return n(v, -8);
    }
    /**
     *  Return a new ``int16`` type for %%v%%.
     */ static int16(v) {
        return n(v, -16);
    }
    /**
     *  Return a new ``int24`` type for %%v%%.
     */ static int24(v) {
        return n(v, -24);
    }
    /**
     *  Return a new ``int32`` type for %%v%%.
     */ static int32(v) {
        return n(v, -32);
    }
    /**
     *  Return a new ``int40`` type for %%v%%.
     */ static int40(v) {
        return n(v, -40);
    }
    /**
     *  Return a new ``int48`` type for %%v%%.
     */ static int48(v) {
        return n(v, -48);
    }
    /**
     *  Return a new ``int56`` type for %%v%%.
     */ static int56(v) {
        return n(v, -56);
    }
    /**
     *  Return a new ``int64`` type for %%v%%.
     */ static int64(v) {
        return n(v, -64);
    }
    /**
     *  Return a new ``int72`` type for %%v%%.
     */ static int72(v) {
        return n(v, -72);
    }
    /**
     *  Return a new ``int80`` type for %%v%%.
     */ static int80(v) {
        return n(v, -80);
    }
    /**
     *  Return a new ``int88`` type for %%v%%.
     */ static int88(v) {
        return n(v, -88);
    }
    /**
     *  Return a new ``int96`` type for %%v%%.
     */ static int96(v) {
        return n(v, -96);
    }
    /**
     *  Return a new ``int104`` type for %%v%%.
     */ static int104(v) {
        return n(v, -104);
    }
    /**
     *  Return a new ``int112`` type for %%v%%.
     */ static int112(v) {
        return n(v, -112);
    }
    /**
     *  Return a new ``int120`` type for %%v%%.
     */ static int120(v) {
        return n(v, -120);
    }
    /**
     *  Return a new ``int128`` type for %%v%%.
     */ static int128(v) {
        return n(v, -128);
    }
    /**
     *  Return a new ``int136`` type for %%v%%.
     */ static int136(v) {
        return n(v, -136);
    }
    /**
     *  Return a new ``int144`` type for %%v%%.
     */ static int144(v) {
        return n(v, -144);
    }
    /**
     *  Return a new ``int52`` type for %%v%%.
     */ static int152(v) {
        return n(v, -152);
    }
    /**
     *  Return a new ``int160`` type for %%v%%.
     */ static int160(v) {
        return n(v, -160);
    }
    /**
     *  Return a new ``int168`` type for %%v%%.
     */ static int168(v) {
        return n(v, -168);
    }
    /**
     *  Return a new ``int176`` type for %%v%%.
     */ static int176(v) {
        return n(v, -176);
    }
    /**
     *  Return a new ``int184`` type for %%v%%.
     */ static int184(v) {
        return n(v, -184);
    }
    /**
     *  Return a new ``int92`` type for %%v%%.
     */ static int192(v) {
        return n(v, -192);
    }
    /**
     *  Return a new ``int200`` type for %%v%%.
     */ static int200(v) {
        return n(v, -200);
    }
    /**
     *  Return a new ``int208`` type for %%v%%.
     */ static int208(v) {
        return n(v, -208);
    }
    /**
     *  Return a new ``int216`` type for %%v%%.
     */ static int216(v) {
        return n(v, -216);
    }
    /**
     *  Return a new ``int224`` type for %%v%%.
     */ static int224(v) {
        return n(v, -224);
    }
    /**
     *  Return a new ``int232`` type for %%v%%.
     */ static int232(v) {
        return n(v, -232);
    }
    /**
     *  Return a new ``int240`` type for %%v%%.
     */ static int240(v) {
        return n(v, -240);
    }
    /**
     *  Return a new ``int248`` type for %%v%%.
     */ static int248(v) {
        return n(v, -248);
    }
    /**
     *  Return a new ``int256`` type for %%v%%.
     */ static int256(v) {
        return n(v, -256);
    }
    /**
     *  Return a new ``int256`` type for %%v%%.
     */ static int(v) {
        return n(v, -256);
    }
    /**
     *  Return a new ``bytes1`` type for %%v%%.
     */ static bytes1(v) {
        return b(v, 1);
    }
    /**
     *  Return a new ``bytes2`` type for %%v%%.
     */ static bytes2(v) {
        return b(v, 2);
    }
    /**
     *  Return a new ``bytes3`` type for %%v%%.
     */ static bytes3(v) {
        return b(v, 3);
    }
    /**
     *  Return a new ``bytes4`` type for %%v%%.
     */ static bytes4(v) {
        return b(v, 4);
    }
    /**
     *  Return a new ``bytes5`` type for %%v%%.
     */ static bytes5(v) {
        return b(v, 5);
    }
    /**
     *  Return a new ``bytes6`` type for %%v%%.
     */ static bytes6(v) {
        return b(v, 6);
    }
    /**
     *  Return a new ``bytes7`` type for %%v%%.
     */ static bytes7(v) {
        return b(v, 7);
    }
    /**
     *  Return a new ``bytes8`` type for %%v%%.
     */ static bytes8(v) {
        return b(v, 8);
    }
    /**
     *  Return a new ``bytes9`` type for %%v%%.
     */ static bytes9(v) {
        return b(v, 9);
    }
    /**
     *  Return a new ``bytes10`` type for %%v%%.
     */ static bytes10(v) {
        return b(v, 10);
    }
    /**
     *  Return a new ``bytes11`` type for %%v%%.
     */ static bytes11(v) {
        return b(v, 11);
    }
    /**
     *  Return a new ``bytes12`` type for %%v%%.
     */ static bytes12(v) {
        return b(v, 12);
    }
    /**
     *  Return a new ``bytes13`` type for %%v%%.
     */ static bytes13(v) {
        return b(v, 13);
    }
    /**
     *  Return a new ``bytes14`` type for %%v%%.
     */ static bytes14(v) {
        return b(v, 14);
    }
    /**
     *  Return a new ``bytes15`` type for %%v%%.
     */ static bytes15(v) {
        return b(v, 15);
    }
    /**
     *  Return a new ``bytes16`` type for %%v%%.
     */ static bytes16(v) {
        return b(v, 16);
    }
    /**
     *  Return a new ``bytes17`` type for %%v%%.
     */ static bytes17(v) {
        return b(v, 17);
    }
    /**
     *  Return a new ``bytes18`` type for %%v%%.
     */ static bytes18(v) {
        return b(v, 18);
    }
    /**
     *  Return a new ``bytes19`` type for %%v%%.
     */ static bytes19(v) {
        return b(v, 19);
    }
    /**
     *  Return a new ``bytes20`` type for %%v%%.
     */ static bytes20(v) {
        return b(v, 20);
    }
    /**
     *  Return a new ``bytes21`` type for %%v%%.
     */ static bytes21(v) {
        return b(v, 21);
    }
    /**
     *  Return a new ``bytes22`` type for %%v%%.
     */ static bytes22(v) {
        return b(v, 22);
    }
    /**
     *  Return a new ``bytes23`` type for %%v%%.
     */ static bytes23(v) {
        return b(v, 23);
    }
    /**
     *  Return a new ``bytes24`` type for %%v%%.
     */ static bytes24(v) {
        return b(v, 24);
    }
    /**
     *  Return a new ``bytes25`` type for %%v%%.
     */ static bytes25(v) {
        return b(v, 25);
    }
    /**
     *  Return a new ``bytes26`` type for %%v%%.
     */ static bytes26(v) {
        return b(v, 26);
    }
    /**
     *  Return a new ``bytes27`` type for %%v%%.
     */ static bytes27(v) {
        return b(v, 27);
    }
    /**
     *  Return a new ``bytes28`` type for %%v%%.
     */ static bytes28(v) {
        return b(v, 28);
    }
    /**
     *  Return a new ``bytes29`` type for %%v%%.
     */ static bytes29(v) {
        return b(v, 29);
    }
    /**
     *  Return a new ``bytes30`` type for %%v%%.
     */ static bytes30(v) {
        return b(v, 30);
    }
    /**
     *  Return a new ``bytes31`` type for %%v%%.
     */ static bytes31(v) {
        return b(v, 31);
    }
    /**
     *  Return a new ``bytes32`` type for %%v%%.
     */ static bytes32(v) {
        return b(v, 32);
    }
    /**
     *  Return a new ``address`` type for %%v%%.
     */ static address(v) {
        return new Typed(_gaurd, "address", v);
    }
    /**
     *  Return a new ``bool`` type for %%v%%.
     */ static bool(v) {
        return new Typed(_gaurd, "bool", !!v);
    }
    /**
     *  Return a new ``bytes`` type for %%v%%.
     */ static bytes(v) {
        return new Typed(_gaurd, "bytes", v);
    }
    /**
     *  Return a new ``string`` type for %%v%%.
     */ static string(v) {
        return new Typed(_gaurd, "string", v);
    }
    /**
     *  Return a new ``array`` type for %%v%%, allowing %%dynamic%% length.
     */ static array(v, dynamic) {
        throw new Error("not implemented yet");
        return new Typed(_gaurd, "array", v, dynamic);
    }
    /**
     *  Return a new ``tuple`` type for %%v%%, with the optional %%name%%.
     */ static tuple(v, name) {
        throw new Error("not implemented yet");
        return new Typed(_gaurd, "tuple", v, name);
    }
    /**
     *  Return a new ``uint8`` type for %%v%%.
     */ static overrides(v) {
        return new Typed(_gaurd, "overrides", Object.assign({}, v));
    }
    /**
     *  Returns true only if %%value%% is a [[Typed]] instance.
     */ static isTyped(value) {
        return value && typeof value === "object" && "_typedSymbol" in value && value._typedSymbol === _typedSymbol;
    }
    /**
     *  If the value is a [[Typed]] instance, validates the underlying value
     *  and returns it, otherwise returns value directly.
     *
     *  This is useful for functions that with to accept either a [[Typed]]
     *  object or values.
     */ static dereference(value, type) {
        if (Typed.isTyped(value)) {
            if (value.type !== type) {
                throw new Error(`invalid type: expecetd ${type}, got ${value.type}`);
            }
            return value.value;
        }
        return value;
    }
} //# sourceMappingURL=typed.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/address.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "AddressCoder",
    ()=>AddressCoder
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/address/address.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/typed.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
;
;
;
;
class AddressCoder extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Coder"] {
    constructor(localName){
        super("address", "address", localName, false);
    }
    defaultValue() {
        return "0x0000000000000000000000000000000000000000";
    }
    encode(writer, _value) {
        let value = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Typed"].dereference(_value, "string");
        try {
            value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"])(value);
        } catch (error) {
            return this._throwError(error.message, _value);
        }
        return writer.writeValue(value);
    }
    decode(reader) {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toBeHex"])(reader.readValue(), 20));
    }
} //# sourceMappingURL=address.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/anonymous.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "AnonymousCoder",
    ()=>AnonymousCoder
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
;
class AnonymousCoder extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Coder"] {
    coder;
    constructor(coder){
        super(coder.name, coder.type, "_", coder.dynamic);
        this.coder = coder;
    }
    defaultValue() {
        return this.coder.defaultValue();
    }
    encode(writer, value) {
        return this.coder.encode(writer, value);
    }
    decode(reader) {
        return this.coder.decode(reader);
    }
} //# sourceMappingURL=anonymous.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/array.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "ArrayCoder",
    ()=>ArrayCoder,
    "pack",
    ()=>pack,
    "unpack",
    ()=>unpack
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/typed.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$anonymous$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/anonymous.js [client] (ecmascript)");
;
;
;
;
function pack(writer, coders, values) {
    let arrayValues = [];
    if (Array.isArray(values)) {
        arrayValues = values;
    } else if (values && typeof values === "object") {
        let unique = {};
        arrayValues = coders.map((coder)=>{
            const name = coder.localName;
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(name, "cannot encode object for signature with missing names", "INVALID_ARGUMENT", {
                argument: "values",
                info: {
                    coder
                },
                value: values
            });
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(!unique[name], "cannot encode object for signature with duplicate names", "INVALID_ARGUMENT", {
                argument: "values",
                info: {
                    coder
                },
                value: values
            });
            unique[name] = true;
            return values[name];
        });
    } else {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid tuple value", "tuple", values);
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(coders.length === arrayValues.length, "types/value length mismatch", "tuple", values);
    let staticWriter = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Writer"]();
    let dynamicWriter = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Writer"]();
    let updateFuncs = [];
    coders.forEach((coder, index)=>{
        let value = arrayValues[index];
        if (coder.dynamic) {
            // Get current dynamic offset (for the future pointer)
            let dynamicOffset = dynamicWriter.length;
            // Encode the dynamic value into the dynamicWriter
            coder.encode(dynamicWriter, value);
            // Prepare to populate the correct offset once we are done
            let updateFunc = staticWriter.writeUpdatableValue();
            updateFuncs.push((baseOffset)=>{
                updateFunc(baseOffset + dynamicOffset);
            });
        } else {
            coder.encode(staticWriter, value);
        }
    });
    // Backfill all the dynamic offsets, now that we know the static length
    updateFuncs.forEach((func)=>{
        func(staticWriter.length);
    });
    let length = writer.appendWriter(staticWriter);
    length += writer.appendWriter(dynamicWriter);
    return length;
}
function unpack(reader, coders) {
    let values = [];
    let keys = [];
    // A reader anchored to this base
    let baseReader = reader.subReader(0);
    coders.forEach((coder)=>{
        let value = null;
        if (coder.dynamic) {
            let offset = reader.readIndex();
            let offsetReader = baseReader.subReader(offset);
            try {
                value = coder.decode(offsetReader);
            } catch (error) {
                // Cannot recover from this
                if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "BUFFER_OVERRUN")) {
                    throw error;
                }
                value = error;
                value.baseType = coder.name;
                value.name = coder.localName;
                value.type = coder.type;
            }
        } else {
            try {
                value = coder.decode(reader);
            } catch (error) {
                // Cannot recover from this
                if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "BUFFER_OVERRUN")) {
                    throw error;
                }
                value = error;
                value.baseType = coder.name;
                value.name = coder.localName;
                value.type = coder.type;
            }
        }
        if (value == undefined) {
            throw new Error("investigate");
        }
        values.push(value);
        keys.push(coder.localName || null);
    });
    return __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Result"].fromItems(values, keys);
}
class ArrayCoder extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Coder"] {
    coder;
    length;
    constructor(coder, length, localName){
        const type = coder.type + "[" + (length >= 0 ? length : "") + "]";
        const dynamic = length === -1 || coder.dynamic;
        super("array", type, localName, dynamic);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            coder,
            length
        });
    }
    defaultValue() {
        // Verifies the child coder is valid (even if the array is dynamic or 0-length)
        const defaultChild = this.coder.defaultValue();
        const result = [];
        for(let i = 0; i < this.length; i++){
            result.push(defaultChild);
        }
        return result;
    }
    encode(writer, _value) {
        const value = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Typed"].dereference(_value, "array");
        if (!Array.isArray(value)) {
            this._throwError("expected array value", value);
        }
        let count = this.length;
        if (count === -1) {
            count = value.length;
            writer.writeValue(value.length);
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgumentCount"])(value.length, count, "coder array" + (this.localName ? " " + this.localName : ""));
        let coders = [];
        for(let i = 0; i < value.length; i++){
            coders.push(this.coder);
        }
        return pack(writer, coders, value);
    }
    decode(reader) {
        let count = this.length;
        if (count === -1) {
            count = reader.readIndex();
            // Check that there is *roughly* enough data to ensure
            // stray random data is not being read as a length. Each
            // slot requires at least 32 bytes for their value (or 32
            // bytes as a link to the data). This could use a much
            // tighter bound, but we are erroring on the side of safety.
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(count * __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["WordSize"] <= reader.dataLength, "insufficient data length", "BUFFER_OVERRUN", {
                buffer: reader.bytes,
                offset: count * __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["WordSize"],
                length: reader.dataLength
            });
        }
        let coders = [];
        for(let i = 0; i < count; i++){
            coders.push(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$anonymous$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AnonymousCoder"](this.coder));
        }
        return unpack(reader, coders);
    }
} //# sourceMappingURL=array.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/boolean.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "BooleanCoder",
    ()=>BooleanCoder
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/typed.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
;
;
class BooleanCoder extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Coder"] {
    constructor(localName){
        super("bool", "bool", localName, false);
    }
    defaultValue() {
        return false;
    }
    encode(writer, _value) {
        const value = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Typed"].dereference(_value, "bool");
        return writer.writeValue(value ? 1 : 0);
    }
    decode(reader) {
        return !!reader.readValue();
    }
} //# sourceMappingURL=boolean.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/bytes.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "BytesCoder",
    ()=>BytesCoder,
    "DynamicBytesCoder",
    ()=>DynamicBytesCoder
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
;
;
class DynamicBytesCoder extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Coder"] {
    constructor(type, localName){
        super(type, type, localName, true);
    }
    defaultValue() {
        return "0x";
    }
    encode(writer, value) {
        value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytesCopy"])(value);
        let length = writer.writeValue(value.length);
        length += writer.writeBytes(value);
        return length;
    }
    decode(reader) {
        return reader.readBytes(reader.readIndex(), true);
    }
}
class BytesCoder extends DynamicBytesCoder {
    constructor(localName){
        super("bytes", localName);
    }
    decode(reader) {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(super.decode(reader));
    }
} //# sourceMappingURL=bytes.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/fixed-bytes.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "FixedBytesCoder",
    ()=>FixedBytesCoder
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/typed.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
;
;
;
class FixedBytesCoder extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Coder"] {
    size;
    constructor(size, localName){
        let name = "bytes" + String(size);
        super(name, name, localName, false);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            size
        }, {
            size: "number"
        });
    }
    defaultValue() {
        return "0x0000000000000000000000000000000000000000000000000000000000000000".substring(0, 2 + this.size * 2);
    }
    encode(writer, _value) {
        let data = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytesCopy"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Typed"].dereference(_value, this.type));
        if (data.length !== this.size) {
            this._throwError("incorrect data length", _value);
        }
        return writer.writeBytes(data);
    }
    decode(reader) {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(reader.readBytes(this.size));
    }
} //# sourceMappingURL=fixed-bytes.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/null.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "NullCoder",
    ()=>NullCoder
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
;
const Empty = new Uint8Array([]);
class NullCoder extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Coder"] {
    constructor(localName){
        super("null", "", localName, false);
    }
    defaultValue() {
        return null;
    }
    encode(writer, value) {
        if (value != null) {
            this._throwError("not null", value);
        }
        return writer.writeBytes(Empty);
    }
    decode(reader) {
        reader.readBytes(0);
        return null;
    }
} //# sourceMappingURL=null.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/number.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "NumberCoder",
    ()=>NumberCoder
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/typed.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
;
;
;
const BN_0 = BigInt(0);
const BN_1 = BigInt(1);
const BN_MAX_UINT256 = BigInt("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
class NumberCoder extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Coder"] {
    size;
    signed;
    constructor(size, signed, localName){
        const name = (signed ? "int" : "uint") + size * 8;
        super(name, name, localName, false);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            size,
            signed
        }, {
            size: "number",
            signed: "boolean"
        });
    }
    defaultValue() {
        return 0;
    }
    encode(writer, _value) {
        let value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Typed"].dereference(_value, this.type));
        // Check bounds are safe for encoding
        let maxUintValue = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["mask"])(BN_MAX_UINT256, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["WordSize"] * 8);
        if (this.signed) {
            let bounds = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["mask"])(maxUintValue, this.size * 8 - 1);
            if (value > bounds || value < -(bounds + BN_1)) {
                this._throwError("value out-of-bounds", _value);
            }
            value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toTwos"])(value, 8 * __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["WordSize"]);
        } else if (value < BN_0 || value > (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["mask"])(maxUintValue, this.size * 8)) {
            this._throwError("value out-of-bounds", _value);
        }
        return writer.writeValue(value);
    }
    decode(reader) {
        let value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["mask"])(reader.readValue(), this.size * 8);
        if (this.signed) {
            value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["fromTwos"])(value, this.size * 8);
        }
        return value;
    }
} //# sourceMappingURL=number.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/string.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "StringCoder",
    ()=>StringCoder
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/utf8.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/typed.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$bytes$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/bytes.js [client] (ecmascript)");
;
;
;
class StringCoder extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$bytes$2e$js__$5b$client$5d$__$28$ecmascript$29$__["DynamicBytesCoder"] {
    constructor(localName){
        super("string", localName);
    }
    defaultValue() {
        return "";
    }
    encode(writer, _value) {
        return super.encode(writer, (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toUtf8Bytes"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Typed"].dereference(_value, "string")));
    }
    decode(reader) {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toUtf8String"])(super.decode(reader));
    }
} //# sourceMappingURL=string.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/tuple.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "TupleCoder",
    ()=>TupleCoder
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/typed.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$array$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/array.js [client] (ecmascript)");
;
;
;
;
class TupleCoder extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Coder"] {
    coders;
    constructor(coders, localName){
        let dynamic = false;
        const types = [];
        coders.forEach((coder)=>{
            if (coder.dynamic) {
                dynamic = true;
            }
            types.push(coder.type);
        });
        const type = "tuple(" + types.join(",") + ")";
        super("tuple", type, localName, dynamic);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            coders: Object.freeze(coders.slice())
        });
    }
    defaultValue() {
        const values = [];
        this.coders.forEach((coder)=>{
            values.push(coder.defaultValue());
        });
        // We only output named properties for uniquely named coders
        const uniqueNames = this.coders.reduce((accum, coder)=>{
            const name = coder.localName;
            if (name) {
                if (!accum[name]) {
                    accum[name] = 0;
                }
                accum[name]++;
            }
            return accum;
        }, {});
        // Add named values
        this.coders.forEach((coder, index)=>{
            let name = coder.localName;
            if (!name || uniqueNames[name] !== 1) {
                return;
            }
            if (name === "length") {
                name = "_length";
            }
            if (values[name] != null) {
                return;
            }
            values[name] = values[index];
        });
        return Object.freeze(values);
    }
    encode(writer, _value) {
        const value = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Typed"].dereference(_value, "tuple");
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$array$2e$js__$5b$client$5d$__$28$ecmascript$29$__["pack"])(writer, this.coders, value);
    }
    decode(reader) {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$array$2e$js__$5b$client$5d$__$28$ecmascript$29$__["unpack"])(reader, this.coders);
    }
} //# sourceMappingURL=tuple.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/fragments.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "ConstructorFragment",
    ()=>ConstructorFragment,
    "ErrorFragment",
    ()=>ErrorFragment,
    "EventFragment",
    ()=>EventFragment,
    "FallbackFragment",
    ()=>FallbackFragment,
    "Fragment",
    ()=>Fragment,
    "FunctionFragment",
    ()=>FunctionFragment,
    "NamedFragment",
    ()=>NamedFragment,
    "ParamType",
    ()=>ParamType,
    "StructFragment",
    ()=>StructFragment
]);
/**
 *  A fragment is a single item from an ABI, which may represent any of:
 *
 *  - [Functions](FunctionFragment)
 *  - [Events](EventFragment)
 *  - [Constructors](ConstructorFragment)
 *  - Custom [Errors](ErrorFragment)
 *  - [Fallback or Receive](FallbackFragment) functions
 *
 *  @_subsection api/abi/abi-coder:Fragments  [about-fragments]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$id$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/hash/id.js [client] (ecmascript)");
;
;
;
// [ "a", "b" ] => { "a": 1, "b": 1 }
function setify(items) {
    const result = new Set();
    items.forEach((k)=>result.add(k));
    return Object.freeze(result);
}
const _kwVisibDeploy = "external public payable override";
const KwVisibDeploy = setify(_kwVisibDeploy.split(" "));
// Visibility Keywords
const _kwVisib = "constant external internal payable private public pure view override";
const KwVisib = setify(_kwVisib.split(" "));
const _kwTypes = "constructor error event fallback function receive struct";
const KwTypes = setify(_kwTypes.split(" "));
const _kwModifiers = "calldata memory storage payable indexed";
const KwModifiers = setify(_kwModifiers.split(" "));
const _kwOther = "tuple returns";
// All Keywords
const _keywords = [
    _kwTypes,
    _kwModifiers,
    _kwOther,
    _kwVisib
].join(" ");
const Keywords = setify(_keywords.split(" "));
// Single character tokens
const SimpleTokens = {
    "(": "OPEN_PAREN",
    ")": "CLOSE_PAREN",
    "[": "OPEN_BRACKET",
    "]": "CLOSE_BRACKET",
    ",": "COMMA",
    "@": "AT"
};
// Parser regexes to consume the next token
const regexWhitespacePrefix = new RegExp("^(\\s*)");
const regexNumberPrefix = new RegExp("^([0-9]+)");
const regexIdPrefix = new RegExp("^([a-zA-Z$_][a-zA-Z0-9$_]*)");
// Parser regexs to check validity
const regexId = new RegExp("^([a-zA-Z$_][a-zA-Z0-9$_]*)$");
const regexType = new RegExp("^(address|bool|bytes([0-9]*)|string|u?int([0-9]*))$");
class TokenString {
    #offset;
    #tokens;
    get offset() {
        return this.#offset;
    }
    get length() {
        return this.#tokens.length - this.#offset;
    }
    constructor(tokens){
        this.#offset = 0;
        this.#tokens = tokens.slice();
    }
    clone() {
        return new TokenString(this.#tokens);
    }
    reset() {
        this.#offset = 0;
    }
    #subTokenString(from = 0, to = 0) {
        return new TokenString(this.#tokens.slice(from, to).map((t)=>{
            return Object.freeze(Object.assign({}, t, {
                match: t.match - from,
                linkBack: t.linkBack - from,
                linkNext: t.linkNext - from
            }));
        }));
    }
    // Pops and returns the value of the next token, if it is a keyword in allowed; throws if out of tokens
    popKeyword(allowed) {
        const top = this.peek();
        if (top.type !== "KEYWORD" || !allowed.has(top.text)) {
            throw new Error(`expected keyword ${top.text}`);
        }
        return this.pop().text;
    }
    // Pops and returns the value of the next token if it is `type`; throws if out of tokens
    popType(type) {
        if (this.peek().type !== type) {
            const top = this.peek();
            throw new Error(`expected ${type}; got ${top.type} ${JSON.stringify(top.text)}`);
        }
        return this.pop().text;
    }
    // Pops and returns a "(" TOKENS ")"
    popParen() {
        const top = this.peek();
        if (top.type !== "OPEN_PAREN") {
            throw new Error("bad start");
        }
        const result = this.#subTokenString(this.#offset + 1, top.match + 1);
        this.#offset = top.match + 1;
        return result;
    }
    // Pops and returns the items within "(" ITEM1 "," ITEM2 "," ... ")"
    popParams() {
        const top = this.peek();
        if (top.type !== "OPEN_PAREN") {
            throw new Error("bad start");
        }
        const result = [];
        while(this.#offset < top.match - 1){
            const link = this.peek().linkNext;
            result.push(this.#subTokenString(this.#offset + 1, link));
            this.#offset = link;
        }
        this.#offset = top.match + 1;
        return result;
    }
    // Returns the top Token, throwing if out of tokens
    peek() {
        if (this.#offset >= this.#tokens.length) {
            throw new Error("out-of-bounds");
        }
        return this.#tokens[this.#offset];
    }
    // Returns the next value, if it is a keyword in `allowed`
    peekKeyword(allowed) {
        const top = this.peekType("KEYWORD");
        return top != null && allowed.has(top) ? top : null;
    }
    // Returns the value of the next token if it is `type`
    peekType(type) {
        if (this.length === 0) {
            return null;
        }
        const top = this.peek();
        return top.type === type ? top.text : null;
    }
    // Returns the next token; throws if out of tokens
    pop() {
        const result = this.peek();
        this.#offset++;
        return result;
    }
    toString() {
        const tokens = [];
        for(let i = this.#offset; i < this.#tokens.length; i++){
            const token = this.#tokens[i];
            tokens.push(`${token.type}:${token.text}`);
        }
        return `<TokenString ${tokens.join(" ")}>`;
    }
}
function lex(text) {
    const tokens = [];
    const throwError = (message)=>{
        const token = offset < text.length ? JSON.stringify(text[offset]) : "$EOI";
        throw new Error(`invalid token ${token} at ${offset}: ${message}`);
    };
    let brackets = [];
    let commas = [];
    let offset = 0;
    while(offset < text.length){
        // Strip off any leading whitespace
        let cur = text.substring(offset);
        let match = cur.match(regexWhitespacePrefix);
        if (match) {
            offset += match[1].length;
            cur = text.substring(offset);
        }
        const token = {
            depth: brackets.length,
            linkBack: -1,
            linkNext: -1,
            match: -1,
            type: "",
            text: "",
            offset,
            value: -1
        };
        tokens.push(token);
        let type = SimpleTokens[cur[0]] || "";
        if (type) {
            token.type = type;
            token.text = cur[0];
            offset++;
            if (type === "OPEN_PAREN") {
                brackets.push(tokens.length - 1);
                commas.push(tokens.length - 1);
            } else if (type == "CLOSE_PAREN") {
                if (brackets.length === 0) {
                    throwError("no matching open bracket");
                }
                token.match = brackets.pop();
                tokens[token.match].match = tokens.length - 1;
                token.depth--;
                token.linkBack = commas.pop();
                tokens[token.linkBack].linkNext = tokens.length - 1;
            } else if (type === "COMMA") {
                token.linkBack = commas.pop();
                tokens[token.linkBack].linkNext = tokens.length - 1;
                commas.push(tokens.length - 1);
            } else if (type === "OPEN_BRACKET") {
                token.type = "BRACKET";
            } else if (type === "CLOSE_BRACKET") {
                // Remove the CLOSE_BRACKET
                let suffix = tokens.pop().text;
                if (tokens.length > 0 && tokens[tokens.length - 1].type === "NUMBER") {
                    const value = tokens.pop().text;
                    suffix = value + suffix;
                    tokens[tokens.length - 1].value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(value);
                }
                if (tokens.length === 0 || tokens[tokens.length - 1].type !== "BRACKET") {
                    throw new Error("missing opening bracket");
                }
                tokens[tokens.length - 1].text += suffix;
            }
            continue;
        }
        match = cur.match(regexIdPrefix);
        if (match) {
            token.text = match[1];
            offset += token.text.length;
            if (Keywords.has(token.text)) {
                token.type = "KEYWORD";
                continue;
            }
            if (token.text.match(regexType)) {
                token.type = "TYPE";
                continue;
            }
            token.type = "ID";
            continue;
        }
        match = cur.match(regexNumberPrefix);
        if (match) {
            token.text = match[1];
            token.type = "NUMBER";
            offset += token.text.length;
            continue;
        }
        throw new Error(`unexpected token ${JSON.stringify(cur[0])} at position ${offset}`);
    }
    return new TokenString(tokens.map((t)=>Object.freeze(t)));
}
// Check only one of `allowed` is in `set`
function allowSingle(set, allowed) {
    let included = [];
    for(const key in allowed.keys()){
        if (set.has(key)) {
            included.push(key);
        }
    }
    if (included.length > 1) {
        throw new Error(`conflicting types: ${included.join(", ")}`);
    }
}
// Functions to process a Solidity Signature TokenString from left-to-right for...
// ...the name with an optional type, returning the name
function consumeName(type, tokens) {
    if (tokens.peekKeyword(KwTypes)) {
        const keyword = tokens.pop().text;
        if (keyword !== type) {
            throw new Error(`expected ${type}, got ${keyword}`);
        }
    }
    return tokens.popType("ID");
}
// ...all keywords matching allowed, returning the keywords
function consumeKeywords(tokens, allowed) {
    const keywords = new Set();
    while(true){
        const keyword = tokens.peekType("KEYWORD");
        if (keyword == null || allowed && !allowed.has(keyword)) {
            break;
        }
        tokens.pop();
        if (keywords.has(keyword)) {
            throw new Error(`duplicate keywords: ${JSON.stringify(keyword)}`);
        }
        keywords.add(keyword);
    }
    return Object.freeze(keywords);
}
// ...all visibility keywords, returning the coalesced mutability
function consumeMutability(tokens) {
    let modifiers = consumeKeywords(tokens, KwVisib);
    // Detect conflicting modifiers
    allowSingle(modifiers, setify("constant payable nonpayable".split(" ")));
    allowSingle(modifiers, setify("pure view payable nonpayable".split(" ")));
    // Process mutability states
    if (modifiers.has("view")) {
        return "view";
    }
    if (modifiers.has("pure")) {
        return "pure";
    }
    if (modifiers.has("payable")) {
        return "payable";
    }
    if (modifiers.has("nonpayable")) {
        return "nonpayable";
    }
    // Process legacy `constant` last
    if (modifiers.has("constant")) {
        return "view";
    }
    return "nonpayable";
}
// ...a parameter list, returning the ParamType list
function consumeParams(tokens, allowIndexed) {
    return tokens.popParams().map((t)=>ParamType.from(t, allowIndexed));
}
// ...a gas limit, returning a BigNumber or null if none
function consumeGas(tokens) {
    if (tokens.peekType("AT")) {
        tokens.pop();
        if (tokens.peekType("NUMBER")) {
            return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(tokens.pop().text);
        }
        throw new Error("invalid gas");
    }
    return null;
}
function consumeEoi(tokens) {
    if (tokens.length) {
        throw new Error(`unexpected tokens at offset ${tokens.offset}: ${tokens.toString()}`);
    }
}
const regexArrayType = new RegExp(/^(.*)\[([0-9]*)\]$/);
function verifyBasicType(type) {
    const match = type.match(regexType);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(match, "invalid type", "type", type);
    if (type === "uint") {
        return "uint256";
    }
    if (type === "int") {
        return "int256";
    }
    if (match[2]) {
        // bytesXX
        const length = parseInt(match[2]);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(length !== 0 && length <= 32, "invalid bytes length", "type", type);
    } else if (match[3]) {
        // intXX or uintXX
        const size = parseInt(match[3]);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(size !== 0 && size <= 256 && size % 8 === 0, "invalid numeric width", "type", type);
    }
    return type;
}
// Make the Fragment constructors effectively private
const _guard = {};
const internal = Symbol.for("_ethers_internal");
const ParamTypeInternal = "_ParamTypeInternal";
const ErrorFragmentInternal = "_ErrorInternal";
const EventFragmentInternal = "_EventInternal";
const ConstructorFragmentInternal = "_ConstructorInternal";
const FallbackFragmentInternal = "_FallbackInternal";
const FunctionFragmentInternal = "_FunctionInternal";
const StructFragmentInternal = "_StructInternal";
class ParamType {
    /**
     *  The local name of the parameter (or ``""`` if unbound)
     */ name;
    /**
     *  The fully qualified type (e.g. ``"address"``, ``"tuple(address)"``,
     *  ``"uint256[3][]"``)
     */ type;
    /**
     *  The base type (e.g. ``"address"``, ``"tuple"``, ``"array"``)
     */ baseType;
    /**
     *  True if the parameters is indexed.
     *
     *  For non-indexable types this is ``null``.
     */ indexed;
    /**
     *  The components for the tuple.
     *
     *  For non-tuple types this is ``null``.
     */ components;
    /**
     *  The array length, or ``-1`` for dynamic-lengthed arrays.
     *
     *  For non-array types this is ``null``.
     */ arrayLength;
    /**
     *  The type of each child in the array.
     *
     *  For non-array types this is ``null``.
     */ arrayChildren;
    /**
     *  @private
     */ constructor(guard, name, type, baseType, indexed, components, arrayLength, arrayChildren){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertPrivate"])(guard, _guard, "ParamType");
        Object.defineProperty(this, internal, {
            value: ParamTypeInternal
        });
        if (components) {
            components = Object.freeze(components.slice());
        }
        if (baseType === "array") {
            if (arrayLength == null || arrayChildren == null) {
                throw new Error("");
            }
        } else if (arrayLength != null || arrayChildren != null) {
            throw new Error("");
        }
        if (baseType === "tuple") {
            if (components == null) {
                throw new Error("");
            }
        } else if (components != null) {
            throw new Error("");
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            name,
            type,
            baseType,
            indexed,
            components,
            arrayLength,
            arrayChildren
        });
    }
    /**
     *  Return a string representation of this type.
     *
     *  For example,
     *
     *  ``sighash" => "(uint256,address)"``
     *
     *  ``"minimal" => "tuple(uint256,address) indexed"``
     *
     *  ``"full" => "tuple(uint256 foo, address bar) indexed baz"``
     */ format(format) {
        if (format == null) {
            format = "sighash";
        }
        if (format === "json") {
            const name = this.name || "";
            if (this.isArray()) {
                const result = JSON.parse(this.arrayChildren.format("json"));
                result.name = name;
                result.type += `[${this.arrayLength < 0 ? "" : String(this.arrayLength)}]`;
                return JSON.stringify(result);
            }
            const result = {
                type: this.baseType === "tuple" ? "tuple" : this.type,
                name
            };
            if (typeof this.indexed === "boolean") {
                result.indexed = this.indexed;
            }
            if (this.isTuple()) {
                result.components = this.components.map((c)=>JSON.parse(c.format(format)));
            }
            return JSON.stringify(result);
        }
        let result = "";
        // Array
        if (this.isArray()) {
            result += this.arrayChildren.format(format);
            result += `[${this.arrayLength < 0 ? "" : String(this.arrayLength)}]`;
        } else {
            if (this.isTuple()) {
                result += "(" + this.components.map((comp)=>comp.format(format)).join(format === "full" ? ", " : ",") + ")";
            } else {
                result += this.type;
            }
        }
        if (format !== "sighash") {
            if (this.indexed === true) {
                result += " indexed";
            }
            if (format === "full" && this.name) {
                result += " " + this.name;
            }
        }
        return result;
    }
    /**
     *  Returns true if %%this%% is an Array type.
     *
     *  This provides a type gaurd ensuring that [[arrayChildren]]
     *  and [[arrayLength]] are non-null.
     */ isArray() {
        return this.baseType === "array";
    }
    /**
     *  Returns true if %%this%% is a Tuple type.
     *
     *  This provides a type gaurd ensuring that [[components]]
     *  is non-null.
     */ isTuple() {
        return this.baseType === "tuple";
    }
    /**
     *  Returns true if %%this%% is an Indexable type.
     *
     *  This provides a type gaurd ensuring that [[indexed]]
     *  is non-null.
     */ isIndexable() {
        return this.indexed != null;
    }
    /**
     *  Walks the **ParamType** with %%value%%, calling %%process%%
     *  on each type, destructing the %%value%% recursively.
     */ walk(value, process) {
        if (this.isArray()) {
            if (!Array.isArray(value)) {
                throw new Error("invalid array value");
            }
            if (this.arrayLength !== -1 && value.length !== this.arrayLength) {
                throw new Error("array is wrong length");
            }
            const _this = this;
            return value.map((v)=>_this.arrayChildren.walk(v, process));
        }
        if (this.isTuple()) {
            if (!Array.isArray(value)) {
                throw new Error("invalid tuple value");
            }
            if (value.length !== this.components.length) {
                throw new Error("array is wrong length");
            }
            const _this = this;
            return value.map((v, i)=>_this.components[i].walk(v, process));
        }
        return process(this.type, value);
    }
    #walkAsync(promises, value, process, setValue) {
        if (this.isArray()) {
            if (!Array.isArray(value)) {
                throw new Error("invalid array value");
            }
            if (this.arrayLength !== -1 && value.length !== this.arrayLength) {
                throw new Error("array is wrong length");
            }
            const childType = this.arrayChildren;
            const result = value.slice();
            result.forEach((value, index)=>{
                childType.#walkAsync(promises, value, process, (value)=>{
                    result[index] = value;
                });
            });
            setValue(result);
            return;
        }
        if (this.isTuple()) {
            const components = this.components;
            // Convert the object into an array
            let result;
            if (Array.isArray(value)) {
                result = value.slice();
            } else {
                if (value == null || typeof value !== "object") {
                    throw new Error("invalid tuple value");
                }
                result = components.map((param)=>{
                    if (!param.name) {
                        throw new Error("cannot use object value with unnamed components");
                    }
                    if (!(param.name in value)) {
                        throw new Error(`missing value for component ${param.name}`);
                    }
                    return value[param.name];
                });
            }
            if (result.length !== this.components.length) {
                throw new Error("array is wrong length");
            }
            result.forEach((value, index)=>{
                components[index].#walkAsync(promises, value, process, (value)=>{
                    result[index] = value;
                });
            });
            setValue(result);
            return;
        }
        const result = process(this.type, value);
        if (result.then) {
            promises.push(async function() {
                setValue(await result);
            }());
        } else {
            setValue(result);
        }
    }
    /**
     *  Walks the **ParamType** with %%value%%, asynchronously calling
     *  %%process%% on each type, destructing the %%value%% recursively.
     *
     *  This can be used to resolve ENS names by walking and resolving each
     *  ``"address"`` type.
     */ async walkAsync(value, process) {
        const promises = [];
        const result = [
            value
        ];
        this.#walkAsync(promises, value, process, (value)=>{
            result[0] = value;
        });
        if (promises.length) {
            await Promise.all(promises);
        }
        return result[0];
    }
    /**
     *  Creates a new **ParamType** for %%obj%%.
     *
     *  If %%allowIndexed%% then the ``indexed`` keyword is permitted,
     *  otherwise the ``indexed`` keyword will throw an error.
     */ static from(obj, allowIndexed) {
        if (ParamType.isParamType(obj)) {
            return obj;
        }
        if (typeof obj === "string") {
            try {
                return ParamType.from(lex(obj), allowIndexed);
            } catch (error) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid param type", "obj", obj);
            }
        } else if (obj instanceof TokenString) {
            let type = "", baseType = "";
            let comps = null;
            if (consumeKeywords(obj, setify([
                "tuple"
            ])).has("tuple") || obj.peekType("OPEN_PAREN")) {
                // Tuple
                baseType = "tuple";
                comps = obj.popParams().map((t)=>ParamType.from(t));
                type = `tuple(${comps.map((c)=>c.format()).join(",")})`;
            } else {
                // Normal
                type = verifyBasicType(obj.popType("TYPE"));
                baseType = type;
            }
            // Check for Array
            let arrayChildren = null;
            let arrayLength = null;
            while(obj.length && obj.peekType("BRACKET")){
                const bracket = obj.pop(); //arrays[i];
                arrayChildren = new ParamType(_guard, "", type, baseType, null, comps, arrayLength, arrayChildren);
                arrayLength = bracket.value;
                type += bracket.text;
                baseType = "array";
                comps = null;
            }
            let indexed = null;
            const keywords = consumeKeywords(obj, KwModifiers);
            if (keywords.has("indexed")) {
                if (!allowIndexed) {
                    throw new Error("");
                }
                indexed = true;
            }
            const name = obj.peekType("ID") ? obj.pop().text : "";
            if (obj.length) {
                throw new Error("leftover tokens");
            }
            return new ParamType(_guard, name, type, baseType, indexed, comps, arrayLength, arrayChildren);
        }
        const name = obj.name;
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(!name || typeof name === "string" && name.match(regexId), "invalid name", "obj.name", name);
        let indexed = obj.indexed;
        if (indexed != null) {
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(allowIndexed, "parameter cannot be indexed", "obj.indexed", obj.indexed);
            indexed = !!indexed;
        }
        let type = obj.type;
        let arrayMatch = type.match(regexArrayType);
        if (arrayMatch) {
            const arrayLength = parseInt(arrayMatch[2] || "-1");
            const arrayChildren = ParamType.from({
                type: arrayMatch[1],
                components: obj.components
            });
            return new ParamType(_guard, name || "", type, "array", indexed, null, arrayLength, arrayChildren);
        }
        if (type === "tuple" || type.startsWith("tuple(" /* fix: ) */ ) || type.startsWith("(" /* fix: ) */ )) {
            const comps = obj.components != null ? obj.components.map((c)=>ParamType.from(c)) : null;
            const tuple = new ParamType(_guard, name || "", type, "tuple", indexed, comps, null, null);
            // @TODO: use lexer to validate and normalize type
            return tuple;
        }
        type = verifyBasicType(obj.type);
        return new ParamType(_guard, name || "", type, type, indexed, null, null, null);
    }
    /**
     *  Returns true if %%value%% is a **ParamType**.
     */ static isParamType(value) {
        return value && value[internal] === ParamTypeInternal;
    }
}
class Fragment {
    /**
     *  The type of the fragment.
     */ type;
    /**
     *  The inputs for the fragment.
     */ inputs;
    /**
     *  @private
     */ constructor(guard, type, inputs){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertPrivate"])(guard, _guard, "Fragment");
        inputs = Object.freeze(inputs.slice());
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            type,
            inputs
        });
    }
    /**
     *  Creates a new **Fragment** for %%obj%%, wich can be any supported
     *  ABI frgament type.
     */ static from(obj) {
        if (typeof obj === "string") {
            // Try parsing JSON...
            try {
                Fragment.from(JSON.parse(obj));
            } catch (e) {}
            // ...otherwise, use the human-readable lexer
            return Fragment.from(lex(obj));
        }
        if (obj instanceof TokenString) {
            // Human-readable ABI (already lexed)
            const type = obj.peekKeyword(KwTypes);
            switch(type){
                case "constructor":
                    return ConstructorFragment.from(obj);
                case "error":
                    return ErrorFragment.from(obj);
                case "event":
                    return EventFragment.from(obj);
                case "fallback":
                case "receive":
                    return FallbackFragment.from(obj);
                case "function":
                    return FunctionFragment.from(obj);
                case "struct":
                    return StructFragment.from(obj);
            }
        } else if (typeof obj === "object") {
            // JSON ABI
            switch(obj.type){
                case "constructor":
                    return ConstructorFragment.from(obj);
                case "error":
                    return ErrorFragment.from(obj);
                case "event":
                    return EventFragment.from(obj);
                case "fallback":
                case "receive":
                    return FallbackFragment.from(obj);
                case "function":
                    return FunctionFragment.from(obj);
                case "struct":
                    return StructFragment.from(obj);
            }
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, `unsupported type: ${obj.type}`, "UNSUPPORTED_OPERATION", {
                operation: "Fragment.from"
            });
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported frgament object", "obj", obj);
    }
    /**
     *  Returns true if %%value%% is a [[ConstructorFragment]].
     */ static isConstructor(value) {
        return ConstructorFragment.isFragment(value);
    }
    /**
     *  Returns true if %%value%% is an [[ErrorFragment]].
     */ static isError(value) {
        return ErrorFragment.isFragment(value);
    }
    /**
     *  Returns true if %%value%% is an [[EventFragment]].
     */ static isEvent(value) {
        return EventFragment.isFragment(value);
    }
    /**
     *  Returns true if %%value%% is a [[FunctionFragment]].
     */ static isFunction(value) {
        return FunctionFragment.isFragment(value);
    }
    /**
     *  Returns true if %%value%% is a [[StructFragment]].
     */ static isStruct(value) {
        return StructFragment.isFragment(value);
    }
}
class NamedFragment extends Fragment {
    /**
     *  The name of the fragment.
     */ name;
    /**
     *  @private
     */ constructor(guard, type, name, inputs){
        super(guard, type, inputs);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(typeof name === "string" && name.match(regexId), "invalid identifier", "name", name);
        inputs = Object.freeze(inputs.slice());
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            name
        });
    }
}
function joinParams(format, params) {
    return "(" + params.map((p)=>p.format(format)).join(format === "full" ? ", " : ",") + ")";
}
class ErrorFragment extends NamedFragment {
    /**
     *  @private
     */ constructor(guard, name, inputs){
        super(guard, "error", name, inputs);
        Object.defineProperty(this, internal, {
            value: ErrorFragmentInternal
        });
    }
    /**
     *  The Custom Error selector.
     */ get selector() {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$id$2e$js__$5b$client$5d$__$28$ecmascript$29$__["id"])(this.format("sighash")).substring(0, 10);
    }
    /**
     *  Returns a string representation of this fragment as %%format%%.
     */ format(format) {
        if (format == null) {
            format = "sighash";
        }
        if (format === "json") {
            return JSON.stringify({
                type: "error",
                name: this.name,
                inputs: this.inputs.map((input)=>JSON.parse(input.format(format)))
            });
        }
        const result = [];
        if (format !== "sighash") {
            result.push("error");
        }
        result.push(this.name + joinParams(format, this.inputs));
        return result.join(" ");
    }
    /**
     *  Returns a new **ErrorFragment** for %%obj%%.
     */ static from(obj) {
        if (ErrorFragment.isFragment(obj)) {
            return obj;
        }
        if (typeof obj === "string") {
            return ErrorFragment.from(lex(obj));
        } else if (obj instanceof TokenString) {
            const name = consumeName("error", obj);
            const inputs = consumeParams(obj);
            consumeEoi(obj);
            return new ErrorFragment(_guard, name, inputs);
        }
        return new ErrorFragment(_guard, obj.name, obj.inputs ? obj.inputs.map(ParamType.from) : []);
    }
    /**
     *  Returns ``true`` and provides a type guard if %%value%% is an
     *  **ErrorFragment**.
     */ static isFragment(value) {
        return value && value[internal] === ErrorFragmentInternal;
    }
}
class EventFragment extends NamedFragment {
    /**
     *  Whether this event is anonymous.
     */ anonymous;
    /**
     *  @private
     */ constructor(guard, name, inputs, anonymous){
        super(guard, "event", name, inputs);
        Object.defineProperty(this, internal, {
            value: EventFragmentInternal
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            anonymous
        });
    }
    /**
     *  The Event topic hash.
     */ get topicHash() {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$id$2e$js__$5b$client$5d$__$28$ecmascript$29$__["id"])(this.format("sighash"));
    }
    /**
     *  Returns a string representation of this event as %%format%%.
     */ format(format) {
        if (format == null) {
            format = "sighash";
        }
        if (format === "json") {
            return JSON.stringify({
                type: "event",
                anonymous: this.anonymous,
                name: this.name,
                inputs: this.inputs.map((i)=>JSON.parse(i.format(format)))
            });
        }
        const result = [];
        if (format !== "sighash") {
            result.push("event");
        }
        result.push(this.name + joinParams(format, this.inputs));
        if (format !== "sighash" && this.anonymous) {
            result.push("anonymous");
        }
        return result.join(" ");
    }
    /**
     *  Return the topic hash for an event with %%name%% and %%params%%.
     */ static getTopicHash(name, params) {
        params = (params || []).map((p)=>ParamType.from(p));
        const fragment = new EventFragment(_guard, name, params, false);
        return fragment.topicHash;
    }
    /**
     *  Returns a new **EventFragment** for %%obj%%.
     */ static from(obj) {
        if (EventFragment.isFragment(obj)) {
            return obj;
        }
        if (typeof obj === "string") {
            try {
                return EventFragment.from(lex(obj));
            } catch (error) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid event fragment", "obj", obj);
            }
        } else if (obj instanceof TokenString) {
            const name = consumeName("event", obj);
            const inputs = consumeParams(obj, true);
            const anonymous = !!consumeKeywords(obj, setify([
                "anonymous"
            ])).has("anonymous");
            consumeEoi(obj);
            return new EventFragment(_guard, name, inputs, anonymous);
        }
        return new EventFragment(_guard, obj.name, obj.inputs ? obj.inputs.map((p)=>ParamType.from(p, true)) : [], !!obj.anonymous);
    }
    /**
     *  Returns ``true`` and provides a type guard if %%value%% is an
     *  **EventFragment**.
     */ static isFragment(value) {
        return value && value[internal] === EventFragmentInternal;
    }
}
class ConstructorFragment extends Fragment {
    /**
     *  Whether the constructor can receive an endowment.
     */ payable;
    /**
     *  The recommended gas limit for deployment or ``null``.
     */ gas;
    /**
     *  @private
     */ constructor(guard, type, inputs, payable, gas){
        super(guard, type, inputs);
        Object.defineProperty(this, internal, {
            value: ConstructorFragmentInternal
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            payable,
            gas
        });
    }
    /**
     *  Returns a string representation of this constructor as %%format%%.
     */ format(format) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(format != null && format !== "sighash", "cannot format a constructor for sighash", "UNSUPPORTED_OPERATION", {
            operation: "format(sighash)"
        });
        if (format === "json") {
            return JSON.stringify({
                type: "constructor",
                stateMutability: this.payable ? "payable" : "undefined",
                payable: this.payable,
                gas: this.gas != null ? this.gas : undefined,
                inputs: this.inputs.map((i)=>JSON.parse(i.format(format)))
            });
        }
        const result = [
            `constructor${joinParams(format, this.inputs)}`
        ];
        if (this.payable) {
            result.push("payable");
        }
        if (this.gas != null) {
            result.push(`@${this.gas.toString()}`);
        }
        return result.join(" ");
    }
    /**
     *  Returns a new **ConstructorFragment** for %%obj%%.
     */ static from(obj) {
        if (ConstructorFragment.isFragment(obj)) {
            return obj;
        }
        if (typeof obj === "string") {
            try {
                return ConstructorFragment.from(lex(obj));
            } catch (error) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid constuctor fragment", "obj", obj);
            }
        } else if (obj instanceof TokenString) {
            consumeKeywords(obj, setify([
                "constructor"
            ]));
            const inputs = consumeParams(obj);
            const payable = !!consumeKeywords(obj, KwVisibDeploy).has("payable");
            const gas = consumeGas(obj);
            consumeEoi(obj);
            return new ConstructorFragment(_guard, "constructor", inputs, payable, gas);
        }
        return new ConstructorFragment(_guard, "constructor", obj.inputs ? obj.inputs.map(ParamType.from) : [], !!obj.payable, obj.gas != null ? obj.gas : null);
    }
    /**
     *  Returns ``true`` and provides a type guard if %%value%% is a
     *  **ConstructorFragment**.
     */ static isFragment(value) {
        return value && value[internal] === ConstructorFragmentInternal;
    }
}
class FallbackFragment extends Fragment {
    /**
     *  If the function can be sent value during invocation.
     */ payable;
    constructor(guard, inputs, payable){
        super(guard, "fallback", inputs);
        Object.defineProperty(this, internal, {
            value: FallbackFragmentInternal
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            payable
        });
    }
    /**
     *  Returns a string representation of this fallback as %%format%%.
     */ format(format) {
        const type = this.inputs.length === 0 ? "receive" : "fallback";
        if (format === "json") {
            const stateMutability = this.payable ? "payable" : "nonpayable";
            return JSON.stringify({
                type,
                stateMutability
            });
        }
        return `${type}()${this.payable ? " payable" : ""}`;
    }
    /**
     *  Returns a new **FallbackFragment** for %%obj%%.
     */ static from(obj) {
        if (FallbackFragment.isFragment(obj)) {
            return obj;
        }
        if (typeof obj === "string") {
            try {
                return FallbackFragment.from(lex(obj));
            } catch (error) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid fallback fragment", "obj", obj);
            }
        } else if (obj instanceof TokenString) {
            const errorObj = obj.toString();
            const topIsValid = obj.peekKeyword(setify([
                "fallback",
                "receive"
            ]));
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(topIsValid, "type must be fallback or receive", "obj", errorObj);
            const type = obj.popKeyword(setify([
                "fallback",
                "receive"
            ]));
            // receive()
            if (type === "receive") {
                const inputs = consumeParams(obj);
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(inputs.length === 0, `receive cannot have arguments`, "obj.inputs", inputs);
                consumeKeywords(obj, setify([
                    "payable"
                ]));
                consumeEoi(obj);
                return new FallbackFragment(_guard, [], true);
            }
            // fallback() [payable]
            // fallback(bytes) [payable] returns (bytes)
            let inputs = consumeParams(obj);
            if (inputs.length) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(inputs.length === 1 && inputs[0].type === "bytes", "invalid fallback inputs", "obj.inputs", inputs.map((i)=>i.format("minimal")).join(", "));
            } else {
                inputs = [
                    ParamType.from("bytes")
                ];
            }
            const mutability = consumeMutability(obj);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(mutability === "nonpayable" || mutability === "payable", "fallback cannot be constants", "obj.stateMutability", mutability);
            if (consumeKeywords(obj, setify([
                "returns"
            ])).has("returns")) {
                const outputs = consumeParams(obj);
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(outputs.length === 1 && outputs[0].type === "bytes", "invalid fallback outputs", "obj.outputs", outputs.map((i)=>i.format("minimal")).join(", "));
            }
            consumeEoi(obj);
            return new FallbackFragment(_guard, inputs, mutability === "payable");
        }
        if (obj.type === "receive") {
            return new FallbackFragment(_guard, [], true);
        }
        if (obj.type === "fallback") {
            const inputs = [
                ParamType.from("bytes")
            ];
            const payable = obj.stateMutability === "payable";
            return new FallbackFragment(_guard, inputs, payable);
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid fallback description", "obj", obj);
    }
    /**
     *  Returns ``true`` and provides a type guard if %%value%% is a
     *  **FallbackFragment**.
     */ static isFragment(value) {
        return value && value[internal] === FallbackFragmentInternal;
    }
}
class FunctionFragment extends NamedFragment {
    /**
     *  If the function is constant (e.g. ``pure`` or ``view`` functions).
     */ constant;
    /**
     *  The returned types for the result of calling this function.
     */ outputs;
    /**
     *  The state mutability (e.g. ``payable``, ``nonpayable``, ``view``
     *  or ``pure``)
     */ stateMutability;
    /**
     *  If the function can be sent value during invocation.
     */ payable;
    /**
     *  The recommended gas limit to send when calling this function.
     */ gas;
    /**
     *  @private
     */ constructor(guard, name, stateMutability, inputs, outputs, gas){
        super(guard, "function", name, inputs);
        Object.defineProperty(this, internal, {
            value: FunctionFragmentInternal
        });
        outputs = Object.freeze(outputs.slice());
        const constant = stateMutability === "view" || stateMutability === "pure";
        const payable = stateMutability === "payable";
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            constant,
            gas,
            outputs,
            payable,
            stateMutability
        });
    }
    /**
     *  The Function selector.
     */ get selector() {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$id$2e$js__$5b$client$5d$__$28$ecmascript$29$__["id"])(this.format("sighash")).substring(0, 10);
    }
    /**
     *  Returns a string representation of this function as %%format%%.
     */ format(format) {
        if (format == null) {
            format = "sighash";
        }
        if (format === "json") {
            return JSON.stringify({
                type: "function",
                name: this.name,
                constant: this.constant,
                stateMutability: this.stateMutability !== "nonpayable" ? this.stateMutability : undefined,
                payable: this.payable,
                gas: this.gas != null ? this.gas : undefined,
                inputs: this.inputs.map((i)=>JSON.parse(i.format(format))),
                outputs: this.outputs.map((o)=>JSON.parse(o.format(format)))
            });
        }
        const result = [];
        if (format !== "sighash") {
            result.push("function");
        }
        result.push(this.name + joinParams(format, this.inputs));
        if (format !== "sighash") {
            if (this.stateMutability !== "nonpayable") {
                result.push(this.stateMutability);
            }
            if (this.outputs && this.outputs.length) {
                result.push("returns");
                result.push(joinParams(format, this.outputs));
            }
            if (this.gas != null) {
                result.push(`@${this.gas.toString()}`);
            }
        }
        return result.join(" ");
    }
    /**
     *  Return the selector for a function with %%name%% and %%params%%.
     */ static getSelector(name, params) {
        params = (params || []).map((p)=>ParamType.from(p));
        const fragment = new FunctionFragment(_guard, name, "view", params, [], null);
        return fragment.selector;
    }
    /**
     *  Returns a new **FunctionFragment** for %%obj%%.
     */ static from(obj) {
        if (FunctionFragment.isFragment(obj)) {
            return obj;
        }
        if (typeof obj === "string") {
            try {
                return FunctionFragment.from(lex(obj));
            } catch (error) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid function fragment", "obj", obj);
            }
        } else if (obj instanceof TokenString) {
            const name = consumeName("function", obj);
            const inputs = consumeParams(obj);
            const mutability = consumeMutability(obj);
            let outputs = [];
            if (consumeKeywords(obj, setify([
                "returns"
            ])).has("returns")) {
                outputs = consumeParams(obj);
            }
            const gas = consumeGas(obj);
            consumeEoi(obj);
            return new FunctionFragment(_guard, name, mutability, inputs, outputs, gas);
        }
        let stateMutability = obj.stateMutability;
        // Use legacy Solidity ABI logic if stateMutability is missing
        if (stateMutability == null) {
            stateMutability = "payable";
            if (typeof obj.constant === "boolean") {
                stateMutability = "view";
                if (!obj.constant) {
                    stateMutability = "payable";
                    if (typeof obj.payable === "boolean" && !obj.payable) {
                        stateMutability = "nonpayable";
                    }
                }
            } else if (typeof obj.payable === "boolean" && !obj.payable) {
                stateMutability = "nonpayable";
            }
        }
        // @TODO: verifyState for stateMutability (e.g. throw if
        //        payable: false but stateMutability is "nonpayable")
        return new FunctionFragment(_guard, obj.name, stateMutability, obj.inputs ? obj.inputs.map(ParamType.from) : [], obj.outputs ? obj.outputs.map(ParamType.from) : [], obj.gas != null ? obj.gas : null);
    }
    /**
     *  Returns ``true`` and provides a type guard if %%value%% is a
     *  **FunctionFragment**.
     */ static isFragment(value) {
        return value && value[internal] === FunctionFragmentInternal;
    }
}
class StructFragment extends NamedFragment {
    /**
     *  @private
     */ constructor(guard, name, inputs){
        super(guard, "struct", name, inputs);
        Object.defineProperty(this, internal, {
            value: StructFragmentInternal
        });
    }
    /**
     *  Returns a string representation of this struct as %%format%%.
     */ format() {
        throw new Error("@TODO");
    }
    /**
     *  Returns a new **StructFragment** for %%obj%%.
     */ static from(obj) {
        if (typeof obj === "string") {
            try {
                return StructFragment.from(lex(obj));
            } catch (error) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid struct fragment", "obj", obj);
            }
        } else if (obj instanceof TokenString) {
            const name = consumeName("struct", obj);
            const inputs = consumeParams(obj);
            consumeEoi(obj);
            return new StructFragment(_guard, name, inputs);
        }
        return new StructFragment(_guard, obj.name, obj.inputs ? obj.inputs.map(ParamType.from) : []);
    }
    // @TODO: fix this return type
    /**
     *  Returns ``true`` and provides a type guard if %%value%% is a
     *  **StructFragment**.
     */ static isFragment(value) {
        return value && value[internal] === StructFragmentInternal;
    }
} //# sourceMappingURL=fragments.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/abi-coder.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "AbiCoder",
    ()=>AbiCoder
]);
/**
 *  When sending values to or receiving values from a [[Contract]], the
 *  data is generally encoded using the [ABI standard](link-solc-abi).
 *
 *  The AbiCoder provides a utility to encode values to ABI data and
 *  decode values from ABI data.
 *
 *  Most of the time, developers should favour the [[Contract]] class,
 *  which further abstracts a lot of the finer details of ABI data.
 *
 *  @_section api/abi/abi-coder:ABI Encoding
 */ // See: https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/address.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$array$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/array.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$boolean$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/boolean.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$bytes$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/bytes.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$fixed$2d$bytes$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/fixed-bytes.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$null$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/null.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$number$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/number.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$string$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/string.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$tuple$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/tuple.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/fragments.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/address/address.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
;
;
;
;
;
;
;
;
;
;
;
;
;
;
// https://docs.soliditylang.org/en/v0.8.17/control-structures.html
const PanicReasons = new Map();
PanicReasons.set(0x00, "GENERIC_PANIC");
PanicReasons.set(0x01, "ASSERT_FALSE");
PanicReasons.set(0x11, "OVERFLOW");
PanicReasons.set(0x12, "DIVIDE_BY_ZERO");
PanicReasons.set(0x21, "ENUM_RANGE_ERROR");
PanicReasons.set(0x22, "BAD_STORAGE_DATA");
PanicReasons.set(0x31, "STACK_UNDERFLOW");
PanicReasons.set(0x32, "ARRAY_RANGE_ERROR");
PanicReasons.set(0x41, "OUT_OF_MEMORY");
PanicReasons.set(0x51, "UNINITIALIZED_FUNCTION_CALL");
const paramTypeBytes = new RegExp(/^bytes([0-9]*)$/);
const paramTypeNumber = new RegExp(/^(u?int)([0-9]*)$/);
let defaultCoder = null;
let defaultMaxInflation = 1024;
function getBuiltinCallException(action, tx, data, abiCoder) {
    let message = "missing revert data";
    let reason = null;
    const invocation = null;
    let revert = null;
    if (data) {
        message = "execution reverted";
        const bytes = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytes"])(data);
        data = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(data);
        if (bytes.length === 0) {
            message += " (no data present; likely require(false) occurred";
            reason = "require(false)";
        } else if (bytes.length % 32 !== 4) {
            message += " (could not decode reason; invalid data length)";
        } else if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(bytes.slice(0, 4)) === "0x08c379a0") {
            // Error(string)
            try {
                reason = abiCoder.decode([
                    "string"
                ], bytes.slice(4))[0];
                revert = {
                    signature: "Error(string)",
                    name: "Error",
                    args: [
                        reason
                    ]
                };
                message += `: ${JSON.stringify(reason)}`;
            } catch (error) {
                message += " (could not decode reason; invalid string data)";
            }
        } else if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(bytes.slice(0, 4)) === "0x4e487b71") {
            // Panic(uint256)
            try {
                const code = Number(abiCoder.decode([
                    "uint256"
                ], bytes.slice(4))[0]);
                revert = {
                    signature: "Panic(uint256)",
                    name: "Panic",
                    args: [
                        code
                    ]
                };
                reason = `Panic due to ${PanicReasons.get(code) || "UNKNOWN"}(${code})`;
                message += `: ${reason}`;
            } catch (error) {
                message += " (could not decode panic code)";
            }
        } else {
            message += " (unknown custom error)";
        }
    }
    const transaction = {
        to: tx.to ? (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"])(tx.to) : null,
        data: tx.data || "0x"
    };
    if (tx.from) {
        transaction.from = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"])(tx.from);
    }
    return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])(message, "CALL_EXCEPTION", {
        action,
        data,
        reason,
        transaction,
        invocation,
        revert
    });
}
class AbiCoder {
    #getCoder(param) {
        if (param.isArray()) {
            return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$array$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ArrayCoder"](this.#getCoder(param.arrayChildren), param.arrayLength, param.name);
        }
        if (param.isTuple()) {
            return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$tuple$2e$js__$5b$client$5d$__$28$ecmascript$29$__["TupleCoder"](param.components.map((c)=>this.#getCoder(c)), param.name);
        }
        switch(param.baseType){
            case "address":
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AddressCoder"](param.name);
            case "bool":
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$boolean$2e$js__$5b$client$5d$__$28$ecmascript$29$__["BooleanCoder"](param.name);
            case "string":
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$string$2e$js__$5b$client$5d$__$28$ecmascript$29$__["StringCoder"](param.name);
            case "bytes":
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$bytes$2e$js__$5b$client$5d$__$28$ecmascript$29$__["BytesCoder"](param.name);
            case "":
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$null$2e$js__$5b$client$5d$__$28$ecmascript$29$__["NullCoder"](param.name);
        }
        // u?int[0-9]*
        let match = param.type.match(paramTypeNumber);
        if (match) {
            let size = parseInt(match[2] || "256");
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(size !== 0 && size <= 256 && size % 8 === 0, "invalid " + match[1] + " bit length", "param", param);
            return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$number$2e$js__$5b$client$5d$__$28$ecmascript$29$__["NumberCoder"](size / 8, match[1] === "int", param.name);
        }
        // bytes[0-9]+
        match = param.type.match(paramTypeBytes);
        if (match) {
            let size = parseInt(match[1]);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(size !== 0 && size <= 32, "invalid bytes length", "param", param);
            return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$fixed$2d$bytes$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FixedBytesCoder"](size, param.name);
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid type", "type", param.type);
    }
    /**
     *  Get the default values for the given %%types%%.
     *
     *  For example, a ``uint`` is by default ``0`` and ``bool``
     *  is by default ``false``.
     */ getDefaultValue(types) {
        const coders = types.map((type)=>this.#getCoder(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ParamType"].from(type)));
        const coder = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$tuple$2e$js__$5b$client$5d$__$28$ecmascript$29$__["TupleCoder"](coders, "_");
        return coder.defaultValue();
    }
    /**
     *  Encode the %%values%% as the %%types%% into ABI data.
     *
     *  @returns DataHexstring
     */ encode(types, values) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgumentCount"])(values.length, types.length, "types/values length mismatch");
        const coders = types.map((type)=>this.#getCoder(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ParamType"].from(type)));
        const coder = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$tuple$2e$js__$5b$client$5d$__$28$ecmascript$29$__["TupleCoder"](coders, "_");
        const writer = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Writer"]();
        coder.encode(writer, values);
        return writer.data;
    }
    /**
     *  Decode the ABI %%data%% as the %%types%% into values.
     *
     *  If %%loose%% decoding is enabled, then strict padding is
     *  not enforced. Some older versions of Solidity incorrectly
     *  padded event data emitted from ``external`` functions.
     */ decode(types, data, loose) {
        const coders = types.map((type)=>this.#getCoder(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ParamType"].from(type)));
        const coder = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$tuple$2e$js__$5b$client$5d$__$28$ecmascript$29$__["TupleCoder"](coders, "_");
        return coder.decode(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Reader"](data, loose, defaultMaxInflation));
    }
    static _setDefaultMaxInflation(value) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(typeof value === "number" && Number.isInteger(value), "invalid defaultMaxInflation factor", "value", value);
        defaultMaxInflation = value;
    }
    /**
     *  Returns the shared singleton instance of a default [[AbiCoder]].
     *
     *  On the first call, the instance is created internally.
     */ static defaultAbiCoder() {
        if (defaultCoder == null) {
            defaultCoder = new AbiCoder();
        }
        return defaultCoder;
    }
    /**
     *  Returns an ethers-compatible [[CallExceptionError]] Error for the given
     *  result %%data%% for the [[CallExceptionAction]] %%action%% against
     *  the Transaction %%tx%%.
     */ static getBuiltinCallException(action, tx, data) {
        return getBuiltinCallException(action, tx, data, AbiCoder.defaultAbiCoder());
    }
} //# sourceMappingURL=abi-coder.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/interface.js [client] (ecmascript) <locals>", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "ErrorDescription",
    ()=>ErrorDescription,
    "Indexed",
    ()=>Indexed,
    "Interface",
    ()=>Interface,
    "LogDescription",
    ()=>LogDescription,
    "TransactionDescription",
    ()=>TransactionDescription
]);
/**
 *  The Interface class is a low-level class that accepts an
 *  ABI and provides all the necessary functionality to encode
 *  and decode paramaters to and results from methods, events
 *  and errors.
 *
 *  It also provides several convenience methods to automatically
 *  search and find matching transactions and events to parse them.
 *
 *  @_subsection api/abi:Interfaces  [interfaces]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$crypto$2f$keccak$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/crypto/keccak.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$id$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/hash/id.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$abi$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/abi-coder.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/coders/abstract-coder.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/fragments.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/typed.js [client] (ecmascript)");
;
;
;
;
;
;
;
;
class LogDescription {
    /**
     *  The matching fragment for the ``topic0``.
     */ fragment;
    /**
     *  The name of the Event.
     */ name;
    /**
     *  The full Event signature.
     */ signature;
    /**
     *  The topic hash for the Event.
     */ topic;
    /**
     *  The arguments passed into the Event with ``emit``.
     */ args;
    /**
     *  @_ignore:
     */ constructor(fragment, topic, args){
        const name = fragment.name, signature = fragment.format();
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            fragment,
            name,
            signature,
            topic,
            args
        });
    }
}
class TransactionDescription {
    /**
     *  The matching fragment from the transaction ``data``.
     */ fragment;
    /**
     *  The name of the Function from the transaction ``data``.
     */ name;
    /**
     *  The arguments passed to the Function from the transaction ``data``.
     */ args;
    /**
     *  The full Function signature from the transaction ``data``.
     */ signature;
    /**
     *  The selector for the Function from the transaction ``data``.
     */ selector;
    /**
     *  The ``value`` (in wei) from the transaction.
     */ value;
    /**
     *  @_ignore:
     */ constructor(fragment, selector, args, value){
        const name = fragment.name, signature = fragment.format();
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            fragment,
            name,
            args,
            signature,
            selector,
            value
        });
    }
}
class ErrorDescription {
    /**
     *  The matching fragment.
     */ fragment;
    /**
     *  The name of the Error.
     */ name;
    /**
     *  The arguments passed to the Error with ``revert``.
     */ args;
    /**
     *  The full Error signature.
     */ signature;
    /**
     *  The selector for the Error.
     */ selector;
    /**
     *  @_ignore:
     */ constructor(fragment, selector, args){
        const name = fragment.name, signature = fragment.format();
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            fragment,
            name,
            args,
            signature,
            selector
        });
    }
}
class Indexed {
    /**
     *  The ``keccak256`` of the value logged.
     */ hash;
    /**
     *  @_ignore:
     */ _isIndexed;
    /**
     *  Returns ``true`` if %%value%% is an **Indexed**.
     *
     *  This provides a Type Guard for property access.
     */ static isIndexed(value) {
        return !!(value && value._isIndexed);
    }
    /**
     *  @_ignore:
     */ constructor(hash){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            hash,
            _isIndexed: true
        });
    }
}
// https://docs.soliditylang.org/en/v0.8.13/control-structures.html?highlight=panic#panic-via-assert-and-error-via-require
const PanicReasons = {
    "0": "generic panic",
    "1": "assert(false)",
    "17": "arithmetic overflow",
    "18": "division or modulo by zero",
    "33": "enum overflow",
    "34": "invalid encoded storage byte array accessed",
    "49": "out-of-bounds array access; popping on an empty array",
    "50": "out-of-bounds access of an array or bytesN",
    "65": "out of memory",
    "81": "uninitialized function"
};
const BuiltinErrors = {
    "0x08c379a0": {
        signature: "Error(string)",
        name: "Error",
        inputs: [
            "string"
        ],
        reason: (message)=>{
            return `reverted with reason string ${JSON.stringify(message)}`;
        }
    },
    "0x4e487b71": {
        signature: "Panic(uint256)",
        name: "Panic",
        inputs: [
            "uint256"
        ],
        reason: (code)=>{
            let reason = "unknown panic code";
            if (code >= 0 && code <= 0xff && PanicReasons[code.toString()]) {
                reason = PanicReasons[code.toString()];
            }
            return `reverted with panic code 0x${code.toString(16)} (${reason})`;
        }
    }
};
class Interface {
    /**
     *  All the Contract ABI members (i.e. methods, events, errors, etc).
     */ fragments;
    /**
     *  The Contract constructor.
     */ deploy;
    /**
     *  The Fallback method, if any.
     */ fallback;
    /**
     *  If receiving ether is supported.
     */ receive;
    #errors;
    #events;
    #functions;
    //    #structs: Map<string, StructFragment>;
    #abiCoder;
    /**
     *  Create a new Interface for the %%fragments%%.
     */ constructor(fragments){
        let abi = [];
        if (typeof fragments === "string") {
            abi = JSON.parse(fragments);
        } else {
            abi = fragments;
        }
        this.#functions = new Map();
        this.#errors = new Map();
        this.#events = new Map();
        //        this.#structs = new Map();
        const frags = [];
        for (const a of abi){
            try {
                frags.push(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Fragment"].from(a));
            } catch (error) {
                console.log(`[Warning] Invalid Fragment ${JSON.stringify(a)}:`, error.message);
            }
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            fragments: Object.freeze(frags)
        });
        let fallback = null;
        let receive = false;
        this.#abiCoder = this.getAbiCoder();
        // Add all fragments by their signature
        this.fragments.forEach((fragment, index)=>{
            let bucket;
            switch(fragment.type){
                case "constructor":
                    if (this.deploy) {
                        console.log("duplicate definition - constructor");
                        return;
                    }
                    //checkNames(fragment, "input", fragment.inputs);
                    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
                        deploy: fragment
                    });
                    return;
                case "fallback":
                    if (fragment.inputs.length === 0) {
                        receive = true;
                    } else {
                        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(!fallback || fragment.payable !== fallback.payable, "conflicting fallback fragments", `fragments[${index}]`, fragment);
                        fallback = fragment;
                        receive = fallback.payable;
                    }
                    return;
                case "function":
                    //checkNames(fragment, "input", fragment.inputs);
                    //checkNames(fragment, "output", (<FunctionFragment>fragment).outputs);
                    bucket = this.#functions;
                    break;
                case "event":
                    //checkNames(fragment, "input", fragment.inputs);
                    bucket = this.#events;
                    break;
                case "error":
                    bucket = this.#errors;
                    break;
                default:
                    return;
            }
            // Two identical entries; ignore it
            const signature = fragment.format();
            if (bucket.has(signature)) {
                return;
            }
            bucket.set(signature, fragment);
        });
        // If we do not have a constructor add a default
        if (!this.deploy) {
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
                deploy: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ConstructorFragment"].from("constructor()")
            });
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            fallback,
            receive
        });
    }
    /**
     *  Returns the entire Human-Readable ABI, as an array of
     *  signatures, optionally as %%minimal%% strings, which
     *  removes parameter names and unneceesary spaces.
     */ format(minimal) {
        const format = minimal ? "minimal" : "full";
        const abi = this.fragments.map((f)=>f.format(format));
        return abi;
    }
    /**
     *  Return the JSON-encoded ABI. This is the format Solidiy
     *  returns.
     */ formatJson() {
        const abi = this.fragments.map((f)=>f.format("json"));
        // We need to re-bundle the JSON fragments a bit
        return JSON.stringify(abi.map((j)=>JSON.parse(j)));
    }
    /**
     *  The ABI coder that will be used to encode and decode binary
     *  data.
     */ getAbiCoder() {
        return __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$abi$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AbiCoder"].defaultAbiCoder();
    }
    // Find a function definition by any means necessary (unless it is ambiguous)
    #getFunction(key, values, forceUnique) {
        // Selector
        if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(key)) {
            const selector = key.toLowerCase();
            for (const fragment of this.#functions.values()){
                if (selector === fragment.selector) {
                    return fragment;
                }
            }
            return null;
        }
        // It is a bare name, look up the function (will return null if ambiguous)
        if (key.indexOf("(") === -1) {
            const matching = [];
            for (const [name, fragment] of this.#functions){
                if (name.split("(" /* fix:) */ )[0] === key) {
                    matching.push(fragment);
                }
            }
            if (values) {
                const lastValue = values.length > 0 ? values[values.length - 1] : null;
                let valueLength = values.length;
                let allowOptions = true;
                if (__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Typed"].isTyped(lastValue) && lastValue.type === "overrides") {
                    allowOptions = false;
                    valueLength--;
                }
                // Remove all matches that don't have a compatible length. The args
                // may contain an overrides, so the match may have n or n - 1 parameters
                for(let i = matching.length - 1; i >= 0; i--){
                    const inputs = matching[i].inputs.length;
                    if (inputs !== valueLength && (!allowOptions || inputs !== valueLength - 1)) {
                        matching.splice(i, 1);
                    }
                }
                // Remove all matches that don't match the Typed signature
                for(let i = matching.length - 1; i >= 0; i--){
                    const inputs = matching[i].inputs;
                    for(let j = 0; j < values.length; j++){
                        // Not a typed value
                        if (!__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Typed"].isTyped(values[j])) {
                            continue;
                        }
                        // We are past the inputs
                        if (j >= inputs.length) {
                            if (values[j].type === "overrides") {
                                continue;
                            }
                            matching.splice(i, 1);
                            break;
                        }
                        // Make sure the value type matches the input type
                        if (values[j].type !== inputs[j].baseType) {
                            matching.splice(i, 1);
                            break;
                        }
                    }
                }
            }
            // We found a single matching signature with an overrides, but the
            // last value is something that cannot possibly be an options
            if (matching.length === 1 && values && values.length !== matching[0].inputs.length) {
                const lastArg = values[values.length - 1];
                if (lastArg == null || Array.isArray(lastArg) || typeof lastArg !== "object") {
                    matching.splice(0, 1);
                }
            }
            if (matching.length === 0) {
                return null;
            }
            if (matching.length > 1 && forceUnique) {
                const matchStr = matching.map((m)=>JSON.stringify(m.format())).join(", ");
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, `ambiguous function description (i.e. matches ${matchStr})`, "key", key);
            }
            return matching[0];
        }
        // Normalize the signature and lookup the function
        const result = this.#functions.get(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FunctionFragment"].from(key).format());
        if (result) {
            return result;
        }
        return null;
    }
    /**
     *  Get the function name for %%key%%, which may be a function selector,
     *  function name or function signature that belongs to the ABI.
     */ getFunctionName(key) {
        const fragment = this.#getFunction(key, null, false);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(fragment, "no matching function", "key", key);
        return fragment.name;
    }
    /**
     *  Returns true if %%key%% (a function selector, function name or
     *  function signature) is present in the ABI.
     *
     *  In the case of a function name, the name may be ambiguous, so
     *  accessing the [[FunctionFragment]] may require refinement.
     */ hasFunction(key) {
        return !!this.#getFunction(key, null, false);
    }
    /**
     *  Get the [[FunctionFragment]] for %%key%%, which may be a function
     *  selector, function name or function signature that belongs to the ABI.
     *
     *  If %%values%% is provided, it will use the Typed API to handle
     *  ambiguous cases where multiple functions match by name.
     *
     *  If the %%key%% and %%values%% do not refine to a single function in
     *  the ABI, this will throw.
     */ getFunction(key, values) {
        return this.#getFunction(key, values || null, true);
    }
    /**
     *  Iterate over all functions, calling %%callback%%, sorted by their name.
     */ forEachFunction(callback) {
        const names = Array.from(this.#functions.keys());
        names.sort((a, b)=>a.localeCompare(b));
        for(let i = 0; i < names.length; i++){
            const name = names[i];
            callback(this.#functions.get(name), i);
        }
    }
    // Find an event definition by any means necessary (unless it is ambiguous)
    #getEvent(key, values, forceUnique) {
        // EventTopic
        if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(key)) {
            const eventTopic = key.toLowerCase();
            for (const fragment of this.#events.values()){
                if (eventTopic === fragment.topicHash) {
                    return fragment;
                }
            }
            return null;
        }
        // It is a bare name, look up the function (will return null if ambiguous)
        if (key.indexOf("(") === -1) {
            const matching = [];
            for (const [name, fragment] of this.#events){
                if (name.split("(" /* fix:) */ )[0] === key) {
                    matching.push(fragment);
                }
            }
            if (values) {
                // Remove all matches that don't have a compatible length.
                for(let i = matching.length - 1; i >= 0; i--){
                    if (matching[i].inputs.length < values.length) {
                        matching.splice(i, 1);
                    }
                }
                // Remove all matches that don't match the Typed signature
                for(let i = matching.length - 1; i >= 0; i--){
                    const inputs = matching[i].inputs;
                    for(let j = 0; j < values.length; j++){
                        // Not a typed value
                        if (!__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$typed$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Typed"].isTyped(values[j])) {
                            continue;
                        }
                        // Make sure the value type matches the input type
                        if (values[j].type !== inputs[j].baseType) {
                            matching.splice(i, 1);
                            break;
                        }
                    }
                }
            }
            if (matching.length === 0) {
                return null;
            }
            if (matching.length > 1 && forceUnique) {
                const matchStr = matching.map((m)=>JSON.stringify(m.format())).join(", ");
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, `ambiguous event description (i.e. matches ${matchStr})`, "key", key);
            }
            return matching[0];
        }
        // Normalize the signature and lookup the function
        const result = this.#events.get(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["EventFragment"].from(key).format());
        if (result) {
            return result;
        }
        return null;
    }
    /**
     *  Get the event name for %%key%%, which may be a topic hash,
     *  event name or event signature that belongs to the ABI.
     */ getEventName(key) {
        const fragment = this.#getEvent(key, null, false);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(fragment, "no matching event", "key", key);
        return fragment.name;
    }
    /**
     *  Returns true if %%key%% (an event topic hash, event name or
     *  event signature) is present in the ABI.
     *
     *  In the case of an event name, the name may be ambiguous, so
     *  accessing the [[EventFragment]] may require refinement.
     */ hasEvent(key) {
        return !!this.#getEvent(key, null, false);
    }
    /**
     *  Get the [[EventFragment]] for %%key%%, which may be a topic hash,
     *  event name or event signature that belongs to the ABI.
     *
     *  If %%values%% is provided, it will use the Typed API to handle
     *  ambiguous cases where multiple events match by name.
     *
     *  If the %%key%% and %%values%% do not refine to a single event in
     *  the ABI, this will throw.
     */ getEvent(key, values) {
        return this.#getEvent(key, values || null, true);
    }
    /**
     *  Iterate over all events, calling %%callback%%, sorted by their name.
     */ forEachEvent(callback) {
        const names = Array.from(this.#events.keys());
        names.sort((a, b)=>a.localeCompare(b));
        for(let i = 0; i < names.length; i++){
            const name = names[i];
            callback(this.#events.get(name), i);
        }
    }
    /**
     *  Get the [[ErrorFragment]] for %%key%%, which may be an error
     *  selector, error name or error signature that belongs to the ABI.
     *
     *  If %%values%% is provided, it will use the Typed API to handle
     *  ambiguous cases where multiple errors match by name.
     *
     *  If the %%key%% and %%values%% do not refine to a single error in
     *  the ABI, this will throw.
     */ getError(key, values) {
        if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(key)) {
            const selector = key.toLowerCase();
            if (BuiltinErrors[selector]) {
                return __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ErrorFragment"].from(BuiltinErrors[selector].signature);
            }
            for (const fragment of this.#errors.values()){
                if (selector === fragment.selector) {
                    return fragment;
                }
            }
            return null;
        }
        // It is a bare name, look up the function (will return null if ambiguous)
        if (key.indexOf("(") === -1) {
            const matching = [];
            for (const [name, fragment] of this.#errors){
                if (name.split("(" /* fix:) */ )[0] === key) {
                    matching.push(fragment);
                }
            }
            if (matching.length === 0) {
                if (key === "Error") {
                    return __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ErrorFragment"].from("error Error(string)");
                }
                if (key === "Panic") {
                    return __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ErrorFragment"].from("error Panic(uint256)");
                }
                return null;
            } else if (matching.length > 1) {
                const matchStr = matching.map((m)=>JSON.stringify(m.format())).join(", ");
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, `ambiguous error description (i.e. ${matchStr})`, "name", key);
            }
            return matching[0];
        }
        // Normalize the signature and lookup the function
        key = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ErrorFragment"].from(key).format();
        if (key === "Error(string)") {
            return __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ErrorFragment"].from("error Error(string)");
        }
        if (key === "Panic(uint256)") {
            return __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ErrorFragment"].from("error Panic(uint256)");
        }
        const result = this.#errors.get(key);
        if (result) {
            return result;
        }
        return null;
    }
    /**
     *  Iterate over all errors, calling %%callback%%, sorted by their name.
     */ forEachError(callback) {
        const names = Array.from(this.#errors.keys());
        names.sort((a, b)=>a.localeCompare(b));
        for(let i = 0; i < names.length; i++){
            const name = names[i];
            callback(this.#errors.get(name), i);
        }
    }
    // Get the 4-byte selector used by Solidity to identify a function
    /*
getSelector(fragment: ErrorFragment | FunctionFragment): string {
    if (typeof(fragment) === "string") {
        const matches: Array<Fragment> = [ ];

        try { matches.push(this.getFunction(fragment)); } catch (error) { }
        try { matches.push(this.getError(<string>fragment)); } catch (_) { }

        if (matches.length === 0) {
            logger.throwArgumentError("unknown fragment", "key", fragment);
        } else if (matches.length > 1) {
            logger.throwArgumentError("ambiguous fragment matches function and error", "key", fragment);
        }

        fragment = matches[0];
    }

    return dataSlice(id(fragment.format()), 0, 4);
}
    */ // Get the 32-byte topic hash used by Solidity to identify an event
    /*
    getEventTopic(fragment: EventFragment): string {
        //if (typeof(fragment) === "string") { fragment = this.getEvent(eventFragment); }
        return id(fragment.format());
    }
    */ _decodeParams(params, data) {
        return this.#abiCoder.decode(params, data);
    }
    _encodeParams(params, values) {
        return this.#abiCoder.encode(params, values);
    }
    /**
     *  Encodes a ``tx.data`` object for deploying the Contract with
     *  the %%values%% as the constructor arguments.
     */ encodeDeploy(values) {
        return this._encodeParams(this.deploy.inputs, values || []);
    }
    /**
     *  Decodes the result %%data%% (e.g. from an ``eth_call``) for the
     *  specified error (see [[getError]] for valid values for
     *  %%key%%).
     *
     *  Most developers should prefer the [[parseCallResult]] method instead,
     *  which will automatically detect a ``CALL_EXCEPTION`` and throw the
     *  corresponding error.
     */ decodeErrorResult(fragment, data) {
        if (typeof fragment === "string") {
            const f = this.getError(fragment);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(f, "unknown error", "fragment", fragment);
            fragment = f;
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(data, 0, 4) === fragment.selector, `data signature does not match error ${fragment.name}.`, "data", data);
        return this._decodeParams(fragment.inputs, (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(data, 4));
    }
    /**
     *  Encodes the transaction revert data for a call result that
     *  reverted from the the Contract with the sepcified %%error%%
     *  (see [[getError]] for valid values for %%fragment%%) with the %%values%%.
     *
     *  This is generally not used by most developers, unless trying to mock
     *  a result from a Contract.
     */ encodeErrorResult(fragment, values) {
        if (typeof fragment === "string") {
            const f = this.getError(fragment);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(f, "unknown error", "fragment", fragment);
            fragment = f;
        }
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["concat"])([
            fragment.selector,
            this._encodeParams(fragment.inputs, values || [])
        ]);
    }
    /**
     *  Decodes the %%data%% from a transaction ``tx.data`` for
     *  the function specified (see [[getFunction]] for valid values
     *  for %%fragment%%).
     *
     *  Most developers should prefer the [[parseTransaction]] method
     *  instead, which will automatically detect the fragment.
     */ decodeFunctionData(fragment, data) {
        if (typeof fragment === "string") {
            const f = this.getFunction(fragment);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(f, "unknown function", "fragment", fragment);
            fragment = f;
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(data, 0, 4) === fragment.selector, `data signature does not match function ${fragment.name}.`, "data", data);
        return this._decodeParams(fragment.inputs, (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(data, 4));
    }
    /**
     *  Encodes the ``tx.data`` for a transaction that calls the function
     *  specified (see [[getFunction]] for valid values for %%fragment%%) with
     *  the %%values%%.
     */ encodeFunctionData(fragment, values) {
        if (typeof fragment === "string") {
            const f = this.getFunction(fragment);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(f, "unknown function", "fragment", fragment);
            fragment = f;
        }
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["concat"])([
            fragment.selector,
            this._encodeParams(fragment.inputs, values || [])
        ]);
    }
    /**
     *  Decodes the result %%data%% (e.g. from an ``eth_call``) for the
     *  specified function (see [[getFunction]] for valid values for
     *  %%key%%).
     *
     *  Most developers should prefer the [[parseCallResult]] method instead,
     *  which will automatically detect a ``CALL_EXCEPTION`` and throw the
     *  corresponding error.
     */ decodeFunctionResult(fragment, data) {
        if (typeof fragment === "string") {
            const f = this.getFunction(fragment);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(f, "unknown function", "fragment", fragment);
            fragment = f;
        }
        let message = "invalid length for result data";
        const bytes = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytesCopy"])(data);
        if (bytes.length % 32 === 0) {
            try {
                return this.#abiCoder.decode(fragment.outputs, bytes);
            } catch (error) {
                message = "could not decode result data";
            }
        }
        // Call returned data with no error, but the data is junk
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, message, "BAD_DATA", {
            value: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(bytes),
            info: {
                method: fragment.name,
                signature: fragment.format()
            }
        });
    }
    makeError(_data, tx) {
        const data = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytes"])(_data, "data");
        const error = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$abi$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AbiCoder"].getBuiltinCallException("call", tx, data);
        // Not a built-in error; try finding a custom error
        const customPrefix = "execution reverted (unknown custom error)";
        if (error.message.startsWith(customPrefix)) {
            const selector = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(data.slice(0, 4));
            const ef = this.getError(selector);
            if (ef) {
                try {
                    const args = this.#abiCoder.decode(ef.inputs, data.slice(4));
                    error.revert = {
                        name: ef.name,
                        signature: ef.format(),
                        args
                    };
                    error.reason = error.revert.signature;
                    error.message = `execution reverted: ${error.reason}`;
                } catch (e) {
                    error.message = `execution reverted (coult not decode custom error)`;
                }
            }
        }
        // Add the invocation, if available
        const parsed = this.parseTransaction(tx);
        if (parsed) {
            error.invocation = {
                method: parsed.name,
                signature: parsed.signature,
                args: parsed.args
            };
        }
        return error;
    }
    /**
     *  Encodes the result data (e.g. from an ``eth_call``) for the
     *  specified function (see [[getFunction]] for valid values
     *  for %%fragment%%) with %%values%%.
     *
     *  This is generally not used by most developers, unless trying to mock
     *  a result from a Contract.
     */ encodeFunctionResult(fragment, values) {
        if (typeof fragment === "string") {
            const f = this.getFunction(fragment);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(f, "unknown function", "fragment", fragment);
            fragment = f;
        }
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(this.#abiCoder.encode(fragment.outputs, values || []));
    }
    /*
        spelunk(inputs: Array<ParamType>, values: ReadonlyArray<any>, processfunc: (type: string, value: any) => Promise<any>): Promise<Array<any>> {
            const promises: Array<Promise<>> = [ ];
            const process = function(type: ParamType, value: any): any {
                if (type.baseType === "array") {
                    return descend(type.child
                }
                if (type. === "address") {
                }
            };
    
            const descend = function (inputs: Array<ParamType>, values: ReadonlyArray<any>) {
                if (inputs.length !== values.length) { throw new Error("length mismatch"); }
                
            };
    
            const result: Array<any> = [ ];
            values.forEach((value, index) => {
                if (value == null) {
                    topics.push(null);
                } else if (param.baseType === "array" || param.baseType === "tuple") {
                    logger.throwArgumentError("filtering with tuples or arrays not supported", ("contract." + param.name), value);
                } else if (Array.isArray(value)) {
                    topics.push(value.map((value) => encodeTopic(param, value)));
                } else {
                    topics.push(encodeTopic(param, value));
                }
            });
        }
    */ // Create the filter for the event with search criteria (e.g. for eth_filterLog)
    encodeFilterTopics(fragment, values) {
        if (typeof fragment === "string") {
            const f = this.getEvent(fragment);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(f, "unknown event", "eventFragment", fragment);
            fragment = f;
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(values.length <= fragment.inputs.length, `too many arguments for ${fragment.format()}`, "UNEXPECTED_ARGUMENT", {
            count: values.length,
            expectedCount: fragment.inputs.length
        });
        const topics = [];
        if (!fragment.anonymous) {
            topics.push(fragment.topicHash);
        }
        // @TODO: Use the coders for this; to properly support tuples, etc.
        const encodeTopic = (param, value)=>{
            if (param.type === "string") {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$id$2e$js__$5b$client$5d$__$28$ecmascript$29$__["id"])(value);
            } else if (param.type === "bytes") {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$crypto$2f$keccak$2e$js__$5b$client$5d$__$28$ecmascript$29$__["keccak256"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(value));
            }
            if (param.type === "bool" && typeof value === "boolean") {
                value = value ? "0x01" : "0x00";
            } else if (param.type.match(/^u?int/)) {
                value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toBeHex"])(value); // @TODO: Should this toTwos??
            } else if (param.type.match(/^bytes/)) {
                value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["zeroPadBytes"])(value, 32);
            } else if (param.type === "address") {
                // Check addresses are valid
                this.#abiCoder.encode([
                    "address"
                ], [
                    value
                ]);
            }
            return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["zeroPadValue"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(value), 32);
        };
        values.forEach((value, index)=>{
            const param = fragment.inputs[index];
            if (!param.indexed) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(value == null, "cannot filter non-indexed parameters; must be null", "contract." + param.name, value);
                return;
            }
            if (value == null) {
                topics.push(null);
            } else if (param.baseType === "array" || param.baseType === "tuple") {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "filtering with tuples or arrays not supported", "contract." + param.name, value);
            } else if (Array.isArray(value)) {
                topics.push(value.map((value)=>encodeTopic(param, value)));
            } else {
                topics.push(encodeTopic(param, value));
            }
        });
        // Trim off trailing nulls
        while(topics.length && topics[topics.length - 1] === null){
            topics.pop();
        }
        return topics;
    }
    encodeEventLog(fragment, values) {
        if (typeof fragment === "string") {
            const f = this.getEvent(fragment);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(f, "unknown event", "eventFragment", fragment);
            fragment = f;
        }
        const topics = [];
        const dataTypes = [];
        const dataValues = [];
        if (!fragment.anonymous) {
            topics.push(fragment.topicHash);
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(values.length === fragment.inputs.length, "event arguments/values mismatch", "values", values);
        fragment.inputs.forEach((param, index)=>{
            const value = values[index];
            if (param.indexed) {
                if (param.type === "string") {
                    topics.push((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$id$2e$js__$5b$client$5d$__$28$ecmascript$29$__["id"])(value));
                } else if (param.type === "bytes") {
                    topics.push((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$crypto$2f$keccak$2e$js__$5b$client$5d$__$28$ecmascript$29$__["keccak256"])(value));
                } else if (param.baseType === "tuple" || param.baseType === "array") {
                    // @TODO
                    throw new Error("not implemented");
                } else {
                    topics.push(this.#abiCoder.encode([
                        param.type
                    ], [
                        value
                    ]));
                }
            } else {
                dataTypes.push(param);
                dataValues.push(value);
            }
        });
        return {
            data: this.#abiCoder.encode(dataTypes, dataValues),
            topics: topics
        };
    }
    // Decode a filter for the event and the search criteria
    decodeEventLog(fragment, data, topics) {
        if (typeof fragment === "string") {
            const f = this.getEvent(fragment);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(f, "unknown event", "eventFragment", fragment);
            fragment = f;
        }
        if (topics != null && !fragment.anonymous) {
            const eventTopic = fragment.topicHash;
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(topics[0], 32) && topics[0].toLowerCase() === eventTopic, "fragment/topic mismatch", "topics[0]", topics[0]);
            topics = topics.slice(1);
        }
        const indexed = [];
        const nonIndexed = [];
        const dynamic = [];
        fragment.inputs.forEach((param, index)=>{
            if (param.indexed) {
                if (param.type === "string" || param.type === "bytes" || param.baseType === "tuple" || param.baseType === "array") {
                    indexed.push(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$fragments$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ParamType"].from({
                        type: "bytes32",
                        name: param.name
                    }));
                    dynamic.push(true);
                } else {
                    indexed.push(param);
                    dynamic.push(false);
                }
            } else {
                nonIndexed.push(param);
                dynamic.push(false);
            }
        });
        const resultIndexed = topics != null ? this.#abiCoder.decode(indexed, (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["concat"])(topics)) : null;
        const resultNonIndexed = this.#abiCoder.decode(nonIndexed, data, true);
        //const result: (Array<any> & { [ key: string ]: any }) = [ ];
        const values = [];
        const keys = [];
        let nonIndexedIndex = 0, indexedIndex = 0;
        fragment.inputs.forEach((param, index)=>{
            let value = null;
            if (param.indexed) {
                if (resultIndexed == null) {
                    value = new Indexed(null);
                } else if (dynamic[index]) {
                    value = new Indexed(resultIndexed[indexedIndex++]);
                } else {
                    try {
                        value = resultIndexed[indexedIndex++];
                    } catch (error) {
                        value = error;
                    }
                }
            } else {
                try {
                    value = resultNonIndexed[nonIndexedIndex++];
                } catch (error) {
                    value = error;
                }
            }
            values.push(value);
            keys.push(param.name || null);
        });
        return __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$coders$2f$abstract$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Result"].fromItems(values, keys);
    }
    /**
     *  Parses a transaction, finding the matching function and extracts
     *  the parameter values along with other useful function details.
     *
     *  If the matching function cannot be found, return null.
     */ parseTransaction(tx) {
        const data = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytes"])(tx.data, "tx.data");
        const value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(tx.value != null ? tx.value : 0, "tx.value");
        const fragment = this.getFunction((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(data.slice(0, 4)));
        if (!fragment) {
            return null;
        }
        const args = this.#abiCoder.decode(fragment.inputs, data.slice(4));
        return new TransactionDescription(fragment, fragment.selector, args, value);
    }
    parseCallResult(data) {
        throw new Error("@TODO");
    }
    /**
     *  Parses a receipt log, finding the matching event and extracts
     *  the parameter values along with other useful event details.
     *
     *  If the matching event cannot be found, returns null.
     */ parseLog(log) {
        const fragment = this.getEvent(log.topics[0]);
        if (!fragment || fragment.anonymous) {
            return null;
        }
        // @TODO: If anonymous, and the only method, and the input count matches, should we parse?
        //        Probably not, because just because it is the only event in the ABI does
        //        not mean we have the full ABI; maybe just a fragment?
        return new LogDescription(fragment, fragment.topicHash, this.decodeEventLog(fragment, log.data, log.topics));
    }
    /**
     *  Parses a revert data, finding the matching error and extracts
     *  the parameter values along with other useful error details.
     *
     *  If the matching error cannot be found, returns null.
     */ parseError(data) {
        const hexData = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(data);
        const fragment = this.getError((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(hexData, 0, 4));
        if (!fragment) {
            return null;
        }
        const args = this.#abiCoder.decode(fragment.inputs, (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(hexData, 4));
        return new ErrorDescription(fragment, fragment.selector, args);
    }
    /**
     *  Creates a new [[Interface]] from the ABI %%value%%.
     *
     *  The %%value%% may be provided as an existing [[Interface]] object,
     *  a JSON-encoded ABI or any Human-Readable ABI format.
     */ static from(value) {
        // Already an Interface, which is immutable
        if (value instanceof Interface) {
            return value;
        }
        // JSON
        if (typeof value === "string") {
            return new Interface(JSON.parse(value));
        }
        // An Interface; possibly from another v6 instance
        if (typeof value.formatJson === "function") {
            return new Interface(value.formatJson());
        }
        // A legacy Interface; from an older version
        if (typeof value.format === "function") {
            return new Interface(value.format("json"));
        }
        // Array of fragments
        return new Interface(value);
    }
} //# sourceMappingURL=interface.js.map
}),
]);

//# sourceMappingURL=f03d5_ethers_lib_esm_abi_7fa2d9bd._.js.map