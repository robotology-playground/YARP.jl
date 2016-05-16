module YARP

export newnet, freenet
export newport, opennewport, openport, openexport, freeport, closeport
export newcontact, setcontactname, freecontact
export setlocalmode
export connectnet, readport, writeport, writewreplyport
export bottleinit
export addstring, addint, adddouble
export newstring, stringtoc, stringfromc, bottlestring

export networkStruct, portStruct

const LIBYARP="libyarpc"

include("YARP_h.jl")

"""
    macro encode(msg)

Allow message passing to yarp IControlMode2 (new mode)
As their C++ code, use a macro
"""
macro encode(msg::AbstractString)
    l = length(msg)
    encoded = Int(l > 3 ? msg[4] : '\0') << 24 + Int(l > 2 ? msg[3] : '\0') << 16 + Int(l > 1 ? msg[2] : '\0') << 8 + Int(msg[1])
    return :( $encoded )
end

"
    newnet()

Create a YARP network"
function newnet()
    ptr = ccall((:yarpNetworkCreate, LIBYARP), networkStruct, ())
    ptr.implementation == C_NULL ? error("Cannot create new network!") : ptr
end

"""
    getnet()

Returns (again) the YARP network pointer
"""
getnet() = ccall((:yarpNetworkGet, LIBYARP), networkStruct, ())

"
    freenet(network::networkStruct)

Free (delete) a yarp network"
function freenet(network::networkStruct)
    ccall((:yarpNetworkFree, LIBYARP), Void, (networkStruct,), network)
end

function setlocalmode(network::networkStruct, setlocal::Int)
    res = ccall((:yarpNetworkSetLocalMode, LIBYARP),
                Cint,
                (networkStruct, Cint),
                network, convert(Cint, setlocal))
    res < 0 ? error("Could not change mode") : res
end

"""
    connectnet(net, src, dest, carrier)

Link port `src` to port `dest` with carrier `carrier` on the YARP network `net`
"""
function connectnet(network::networkStruct,
                    src::AbstractString,
                    dest::AbstractString,
                    carrier::AbstractString)
    res = ccall((:yarpNetworkConnect, LIBYARP),
                Cint,
                (networkStruct, Cstring, Cstring, Cstring),
                network, src, dest, carrier)
    res < 0 ? error("Could not connect!") : res
end

"""
    disconnectnet(net, src, dest)

Diconnect link from port `src` to port `dst` on YARP network `net`
"""
function disconnectnet(network::networkStruct,
                    src::AbstractString,
                    dest::AbstractString)
    res = ccall((:yarpNetworkDisconnect, LIBYARP),
                Cint,
                (networkStruct, Cstring, Cstring),
                network, src, dest)
    res < 0 ? error("Could not disconnect!") : res
end

"""
    newport(net)
Creates a YARP port on network `net`, and returns the pointer.
After the creation, it needs to be opened (with `openport(port, name)`)
"""
function newport(network::networkStruct)
    ptr = ccall((:yarpPortCreate, LIBYARP),
                portStruct,
                (networkStruct,),
                network)
    ptr.implementation == C_NULL ? error("Cannot create new port!") : ptr
end

"""
    opneport(port, name)
Opens a previously created port `port`, called `name`
"""
function openport(port::portStruct, name::AbstractString)
    res = ccall((:yarpPortOpen, LIBYARP),
                Cint,
                (portStruct, Cstring),
                port, name)
    res < 0  ? error("Cannot create new port!") : res
end


"""
    opennewport(net, name)
Short for `newport(net)`, `openport(port, name)`
"""
function opennewport(network::networkStruct, name::AbstractString)
    ptr = ccall((:yarpPortCreateOpen, LIBYARP),
                portStruct,
                (networkStruct, Cstring),
                network, name)
    ptr.implementation == C_NULL ? error("Cannot create new port!") : ptr
end

"""
    closeport(port)
Closes an opened port
"""
function closeport(port::portStruct)
    res = ccall((:yarpPortClose, LIBYARP),
                Cint,
                (portStruct,),
                port)
    res < 0 ? error("Could not close port") : res    
end

"""
"""
function freeport(port::portStruct)
    ccall((:yarpPortFree, LIBYARP), Void, (portStruct,), port)
end

function openexport(port::portStruct, contact::contactStruct)
    res = ccall((:yarpPortOpenEx, LIBYARP),
                Cint,
                (portStruct, contactStruct),
                port, contact)
    res < 0 ? error("Could not open port") : res
end

function enablebgw(port::portStruct, flag::Int)
    res = ccall((:yarpPortEnableBackgroundWrite, LIBYARP),
                Cint,
                (portStruct, Cint),
                port, flag)
    res < 0 ? error("Could not enable background") : res
end

function writeport(port::portStruct, msg::portableStruct)
    res = ccall((:yarpPortWrite, LIBYARP),
                Cint,
                (portStruct, Ref{portableStruct}),
                port, msg)
    res < 0 ? error("Could not write to port") : res
end

function readport(port::portStruct, msg::portableStruct, willreply::Int)
    res = ccall((:yarpPortRead, LIBYARP),
                Cint,
                (portStruct, Ref{portableStruct}, Cint),
                port, msg, willreply)
    res < 0 ? error("Could not read") : res
    res
end

function replyport(port::portStruct, msg::portableStruct)
    res = ccall((:yarpPortReply, LIBYARP),
                Cint,
                (portStruct, Ref{portableStruct}),
                port, msg)
    res < 0 ? error("Could not read") : res    
end

function writewreplyport(port::portStruct,
                         msg::portableStruct,
                         reply::portableStruct)
    res = ccall((:yarpPortWriteWithReply, LIBYARP),
                Cint,
                (portStruct,
                 Ref{portableStruct},
                 Ref{portableStruct}),
                port, msg, reply)
    res < 0 ? error("Could not write/read") : res        
end

function newcontact()
    ptr = ccall((:yarpContactCreate, LIBYARP), contactStruct, ())
    ptr.implementation == C_NULL ? error("Cannot create new contact!") : ptr
end

function freecontact(contact::contactStruct)
    ccall((:yarpContactFree, LIBYARP), Void, (contactStruct,), contact)
end

function setcontactname(contact::contactStruct, name::AbstractString)
    res = ccall((:yarpContactSetName, LIBYARP),
                Cint,
                (contactStruct, Cstring),
                contact, name)
    res < 0 ? error("Could not set name!") : res
end

function readertextmode(reader::readerStruct)
    res = ccall((:yarpReaderIsTextMode, LIBYARP),
                Cint,
                (readerStruct,),
                reader)
    res < 0 ? error("Could not obtain details!") : res
end

## function expecttextreader(reader::Ptr{UInt8}, str::AbstractString, terminal

newstring() = ccall((:yarpStringCreate, LIBYARP), yarpstring, ())

freestring(string::yarpstring) = ccall((:yarpStringFree, LIBYARP), Void, (yarpstring,), string)

function stringtoc(string::yarpstring)
    bytestring(ccall((:yarpStringToC, LIBYARP),
         Cstring,
         (yarpstring,),
         string))
end

function stringfromc(string::yarpstring, text::AbstractString)
    ccall((:yarpStringFromC, LIBYARP),
         Cint,
         (yarpstring, Cstring),
         string, text)
end

timedelay(seconds::Float64) = ccall((:yarpTimeDelay, LIBYARP), Void, (Cdouble,), seconds)
timenow() = ccall((:yarpTimeNow, LIBYARP), Cdouble, ())
timeyield() = ccall((:yarpTimeYield, LIBYARP), Void, ())

function bottleinit(bottle::portableStruct)
    res = ccall((:yarpBottleInit, LIBYARP), Cint, (Ref{portableStruct},), bottle)
    res < 0 ? error("Could not init bottle") : res
end

"Overload of bottleinit"
function bottleinit()
    bottle = portableStruct()
    bottleinit(bottle)
    bottle
end

function bottlefini(bottle::portableStruct)
    res = ccall((:yarpBottleFini, LIBYARP), Cint, (Ref{portableStruct},), bottle)
    res < 0 ? error("Could not close bottle") : res
end

function addint(bottle::portableStruct, x::Int)
    ccall((:yarpBottleAddInt, LIBYARP),
          Void, (Ref{portableStruct}, Cint),
          bottle, x)
end

function adddouble(bottle::portableStruct, x::Float64)
    ccall((:yarpBottleAddDouble, LIBYARP),
          Void, (Ref{portableStruct}, Cdouble),
          bottle, x)
end

function addstring(bottle::portableStruct, x::AbstractString)
    ccall((:yarpBottleAddString, LIBYARP),
          Void, (Ref{portableStruct}, Cstring),
          bottle, x)
end

function bottleread(bottle::portableStruct, connection::readerStruct)
    res = ccall((:yarpBottleRead, LIBYARP), Cint,
                (Ref{portableStruct}, readerStruct),
                bottle, connection)
    res < 0 ? error("Could not read bottle") : res
end

function bottlestring(bottle::portableStruct, result::yarpstring)
    res = ccall((:yarpBottleToString, LIBYARP), Cint,
                (Ref{portableStruct}, yarpstring),
                bottle, result)
    res < 0 ? error("Could not convert bottle to string") : res   
end

include("gazebo.jl")

end ## module

