module gazebo

using YARP

## IControlMode2
export setControlMode

"Helper for text bottle creation"
function newbottle(action::ASCIIString, what::ASCIIString, value::Int)
    bottle = newbottle()
    addstring(bottle, action)
    addstring(bottle, what)
    addint(bottle, value)
    bottle
end

function newbottle(msg::ASCIIString)
    bottle = YARP.portableStruct()
    bottleinit(bottle)
    addstring(bottle, msg)
    bottle
end

function newbottle(msgs::Vector{ASCIIString})
    bottle = YARP.portableStruct()
    bottleinit(bottle)
    [ addstring(bottle, msg) for msg in msgs ]
    bottle
end

"""
    newbottle()

Create and initialize a yarp bottle"""
function newbottle()
    input = YARP.portableStruct()
    YARP.bottleinit(input)
    input
end

## Create prapared output bottles, for faster sending
## FIXME: add missing
## TODO: convert to macro?

const bottlerack = Dict("step" => newbottle("stepSimulation"),
                        "stepAndWait" => newbottle("stepSimulationAndWait"),
                        "reset" => newbottle("resetSimulationTime"),
                        "pause" => newbottle("pauseSimulation"),
                        "continue" => newbottle("continueSimulation"),
                        "time" => newbottle("getSimulationTime"),
                        "getaxes" => newbottle(["get", "axes"]),
                        "motiondone" => newbottle(["get", "dons"]),
                        "help" => newbottle(["help", "more"]))

const regexrack = Dict("axes" => r".*axes\s([0-9]+).*",
                       "encs" => r".*enc\s([0-9\.\-]+).*",
                       "dons" => r"dons ([01]) .*")

"Helper for yarp opennewport and yarp connectnet"
function connect(net::networkStruct,
                 writername::AbstractString,
                 outputport::AbstractString;
                 contype::AbstractString = "shmem")
    writer = opennewport(net, writername)
    connectnet(net, writername, outputport, contype)
    writer
end

"""
    pause(portStruct)

Helper for pausing gazebo world
"""
function pause(writer::portStruct)
    input = newbottle()
    YARP.writewreplyport(writer, newbottle("stepSimulation"), input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    YARP.stringtoc(text) == "[done]"
end

"""
    start(portStruct)

Helper for starting gazebo world
"""
function start(writer::portStruct)
    input = newbottle()
    YARP.writewreplyport(writer, newbottle("continueSimulation"), input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    YARP.stringtoc(text)
end

reset(writer, positions) = setposs(writer, positions)

function reset(writer::portStruct) ## Reset clock
    input = newbottle()
    YARP.writewreplyport(writer, newbottle("resetSimulationTime"), input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    YARP.stringtoc(text) == "[done]"
end

function simtime(writer::portStruct)
    input = newbottle()
    YARP.writewreplyport(writer, newbottle("getSimulationTime"), input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    parse(Float64, YARP.stringtoc(text))
end

function step(writer::portStruct;blocking::Bool = false)
    input = newbottle()
    if ! blocking
        output = newbottle("stepSimulation")
    else
        output = newbottle("stepSimulationAndWait")
    end
    YARP.writewreplyport(writer, output, input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    YARP.stringtoc(text) != "[fail]" ? true : error("Could not step")
end

function getenc(writer::portStruct, jnt::Int)
    text = YARP.newstring()
    input = newbottle()
    output = newbottle("get", "enc", jnt)
    writewreplyport(writer, output, input)
    bottlestring(input, text)
    stringtoc(text)
end

function getaxes(writer::portStruct)
    input = newbottle()
    text = YARP.newstring()
    writewreplyport(writer, newbottle(["get","axes"]), input)
    bottlestring(input, text)
    parse(Int, match(regexrack["axes"], stringtoc(text))[1])
end


function angle(writer::portStruct, jnt::Int) ## TODO: check for multiple joint
    text = getenc(writer, jnt)
    if ismatch(regexrack["encs"], text)
        parse(Float64, match(regexrack["encs"], text)[1])
    else
        error("Read fail")
    end
end


function checkmotiondone(writer::portStruct)
    text = YARP.newstring()
    input = newbottle()
    YARP.writewreplyport(writer, newbottle(["get", "dons"]), input)
    YARP.bottlestring(input, text)
    Bool(parse(Int, match(regexrack["dons"], YARP.stringtoc(text))[1]))
end

function setposs(writer::portStruct, values::Tuple{Float64})
    ## TODO: checkme
    text = YARP.newstring()
    input = YARP.portableStruct()
    YARP.bottleinit(input)
    output = YARP.portableStruct()
    YARP.bottleinit(output)
    addstring(output, "set")
    addstring(output, "poss")
    for v in values
        adddouble(output, v)
    end
    writewreplyport(writer, output, input)
    bottlestring(input, text)
    stringtoc(text)
end

function help(writer)
    text = YARP.newstring()
    input = newbottle()
    writewreplyport(writer, newbottle(["help", "more"]), input)
    bottlestring(input, text)
    stringtoc(text)
end

macro set(bottle, args...)
    quote
        text = YARP.newstring()
        input = YARP.bottleinit()
        output = YARP.bottleinit()
        for arg in $args
            if isa(arg, Float64)
                YARP.adddouble($bottle, arg)
            elseif isa(arg, Int)
                YARP.addint($bottle, arg)
            elseif isa(arg, ASCIIString)
                YARP.addstring($bottle, arg)
            else
                error("Setting an unknown type!")
            end
        end
        
        writewreplyport(writer, output, input)
        bottlestring(input, text)
        stringtoc(text) == "[ok]"
    end
end

## @set(input,"come",1.2, 1)

function set1V1I1D(writer::portStruct, code::Int, jnt::Int, value::Float64)
    text = YARP.newstring()
    input = YARP.portableStruct()
    YARP.bottleinit(input)
    output = YARP.portableStruct()
    YARP.bottleinit(output)
    addint(output, @YARP.encode("set"))
    addint(output, code)
    addint(output, jnt)
    adddouble(output, value)
    writewreplyport(writer, output, input)
    bottlestring(input, text)
    stringtoc(text) == "[ok]"
end

function setvel(writer::portStruct, jnt::Int, speed::Float64)
    text = YARP.newstring()
    input = YARP.portableStruct()
    YARP.bottleinit(input)
    output = YARP.portableStruct()
    YARP.bottleinit(output)
    addstring(output, "set")
    addstring(output, "vel")
    addint(output, jnt)
    adddouble(output, speed)
    writewreplyport(writer, output, input)
    bottlestring(input, text)
    stringtoc(text) == "[ok]"
end

function setpos(writer::portStruct, jnt::Int, pos::Float64)
    ## FIXME: Can be sped-up if needed
    text = YARP.newstring()
    input = newbottle()
    output = YARP.portableStruct()
    YARP.bottleinit(output)
    addstring(output, "set")
    addstring(output, "pos")
    addint(output, jnt)
    adddouble(output, pos)
    writewreplyport(writer, output, input)
    bottlestring(input, text)
    stringtoc(text) == "[ok]"
end

### IControlMode2
function setControlMode(writer::portStruct, joint::Int, mode::Int)
    bottle = gazebo.newbottle()
    gazebo.addint(bottle, @YARP.encode("set"))
    gazebo.addint(bottle, @YARP.encode("icmd"))
    gazebo.addint(bottle, @YARP.encode("cmod"))
    gazebo.addint(bottle, joint)
    gazebo.addint(bottle, mode)
    input = gazebo.newbottle()
    YARP.writewreplyport(writer, bottle, input)
    text = YARP.newstring()
    gazebo.bottlestring(input, text)
    gazebo.stringtoc(text) != "[fail]"
end

function setInteraction(writer::portStruct, axis::Int, mode::Int)
    bottle = gazebo.newbottle()
    gazebo.addint(bottle, @YARP.encode("set"))
    gazebo.addint(bottle, @YARP.encode("intm"))
    gazebo.addint(bottle, @YARP.encode("mode"))
    gazebo.addint(bottle, axis)
    gazebo.addint(bottle, @YARP.encode("stif"))
    
    input = gazebo.newbottle()
    YARP.writewreplyport(writer, bottle, input)
    text = YARP.newstring()
    gazebo.bottlestring(input, text)
    gazebo.stringtoc(text) != "[fail]"
end

function get1V1I()
    
end

end ## module
