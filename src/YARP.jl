module YARP

export newnet, freenet
export newport, opennewport, openport, openexport, freeport, closeport
export newcontact, setcontactname, freecontact
export setlocalmode
export connectnet, readport, writeport, writewreplyport
export addstring, addint, adddouble
export newstring, stringtoc, stringfromc, bottlestring

const LIBYARP="libyarpc"
include("YARP_h.jl")

"
    newnet()

Create a YARP network"
function newnet()
    ptr = ccall((:yarpNetworkCreate, LIBYARP), networkStruct, ())
    ptr.implementation == C_NULL ? error("Cannot create new network!") : ptr
end

"
    freenet(network::networkStruct)

Free (delete) a yarp network"
function freenet(network::networkStruct)
    ccall((:yarpNetworkFree, LIBYARP), Void, (networkStruct,), network)
end

getnet() = ccall((:yarpNetworkGet, LIBYARP), networkStruct, ())

function setlocalmode(network::networkStruct, setlocal::Int)
    res = ccall((:yarpNetworkSetLocalMode, LIBYARP),
                Cint,
                (networkStruct, Cint),
                network, convert(Cint, setlocal))
    res < 0 ? error("Could not change mode") : res
end

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

function disconnectnet(network::networkStruct,
                    src::AbstractString,
                    dest::AbstractString)
    res = ccall((:yarpNetworkDisconnect, LIBYARP),
                Cint,
                (networkStruct, Cstring, Cstring),
                network, src, dest)
    res < 0 ? error("Could not disconnect!") : res
end

function newport(network::networkStruct)
    ptr = ccall((:yarpPortCreate, LIBYARP),
                portStruct,
                (networkStruct,),
                network)
    ptr.implementation == C_NULL ? error("Cannot create new port!") : ptr
end

function opennewport(network::networkStruct, name::AbstractString)
    ptr = ccall((:yarpPortCreateOpen, LIBYARP),
                portStruct,
                (networkStruct, Cstring),
                network, name)
    ptr.implementation == C_NULL ? error("Cannot create new port!") : ptr
end

function freeport(port::portStruct)
    ccall((:yarpPortFree, LIBYARP), Void, (portStruct,), port)
end

function openport(port::portStruct, name::AbstractString)
    res = ccall((:yarpPortOpen, LIBYARP),
                Cint,
                (portStruct, Cstring),
                port, name)
    res < 0  ? error("Cannot create new port!") : res
end

function openexport(port::portStruct, contact::contactStruct)
    res = ccall((:yarpPortOpenEx, LIBYARP),
                Cint,
                (portStruct, contactStruct),
                port, contact)
    res < 0 ? error("Could not open port") : res
end

function closeport(port::portStruct)
    res = ccall((:yarpPortClose, LIBYARP),
                Cint,
                (portStruct,),
                port)
    res < 0 ? error("Could not close port") : res    
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
    bottle = YARP.portableStruct()
    YARP.bottleinit(bottle)
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
adddouble(bottle::portableStruct, x::Int) = adddouble(bottle, Float64(x))

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

end ## module

