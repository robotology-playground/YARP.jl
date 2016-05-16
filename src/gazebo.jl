module gazebo

using YARP

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

function pause(writer::portStruct)
    input = newbottle()
    YARP.writewreplyport(writer, bottlerack["pause"], input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    YARP.stringtoc(text)
end

function start(writer::portStruct)
    input = newbottle()
    YARP.writewreplyport(writer, bottlerack["continue"], input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    YARP.stringtoc(text)
end

reset(writer, positions) = setposs(writer, positions)

function reset(writer::portStruct) ## Reset clock
    input = newbottle()
    YARP.writewreplyport(writer, bottlerack["reset"], input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    YARP.stringtoc(text) == "[done]"
end

function simtime(writer::portStruct)
    input = newbottle()
    YARP.writewreplyport(writer, bottlerack["time"], input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    parse(Float64, YARP.stringtoc(text))
end

function step(writer::portStruct;blocking::Bool = false)
    input = newbottle()
    if ! blocking
        output = bottlerack["step"]
    else
        output = bottlerack["stepAndWait"]
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
    output = 
    writewreplyport(writer, bottlerack["getaxes"], input)
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
    YARP.writewreplyport(writer, bottlerack["motiondone"], input)
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
    writewreplyport(writer, bottlerack["help"], input)
    bottlestring(input, text)
    stringtoc(text)
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

end ## module
