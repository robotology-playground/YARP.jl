module gazebo

using YARP

"Helper for text bottle creation"
function newbottle(msg::AbstractString)
    bottle = YARP.portableStruct()
    bottleinit(bottle)
    addstring(bottle, msg)
    bottle
end

## Create prapared output bottles, for faster sending
const bottlerack = Dict(
 "step" => newbottle("stepSimulation"),
 "stepAndWait" => newbottle("stepSimulationAndWait"),
 "reset" => newbottle("resetSimulationTime"),
 "pause" => newbottle("pauseSimulation")
 ## FIXME: add missing
 ## TODO: convert to macro?
)

"Helper for yarp opennewport and yarp connectnet"
function connect(net,
                 writername::AbstractString,
                 outputport::AbstractString;
                 contype = "shmem")
    writer = opennewport(net, writername)
    connectnet(net, writername, outputport, contype)
    writer
end

function pause(writer)
    input = YARP.portableStruct()
    YARP.bottleinit(input)
    output = YARP.portableStruct()
    YARP.bottleinit(output)
    addstring(output, "pauseSimulation")
    YARP.writewreplyport(writer, output, input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    YARP.stringtoc(text)
end

function reset(writer)
    input = YARP.portableStruct()
    YARP.bottleinit(input)
    output = YARP.portableStruct()
    YARP.bottleinit(output)
    addstring(output, "resetSimulationTime")
    YARP.writewreplyport(writer, output, input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    YARP.stringtoc(text)
end

function post(writer, output, input)
    input = bottleinit()
    output = bottleinit()

    YARP.writewreplyport(writer, output, input)
end

function simtime(writer)
    input = YARP.portableStruct()
    YARP.bottleinit(input)
    output = YARP.portableStruct()
    YARP.bottleinit(output)
    addstring(output, "getSimulationTime")
    YARP.writewreplyport(writer, output, input)
    text = YARP.newstring()    
    YARP.bottlestring(input, text)
    parse(Float64, YARP.stringtoc(text))
end

function step(writer;blocking = false)
    input = YARP.portableStruct()
    YARP.bottleinit(input)
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

## ## Get motion done
## "get" "don"
## ## Get motions done
## "get" "dons"

function angle(writer, jnt) ## TODO: check for multiple joint
    text = getenc(writer, jnt)
    regex = r".*enc\s([0-9\.\-]+).*"
    if ismatch(regex, text)
        parse(Float64, match(regex, text)[1])
    else
        error("Read fail")
    end
end

function setposs(writer, values::Tuple{Float64})
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

function getenc(writer, jnt)
    text = YARP.newstring()
    input = YARP.portableStruct()
    YARP.bottleinit(input)
    ## TODO: prepare output with a macro?
    output = YARP.portableStruct()
    YARP.bottleinit(output)
    addstring(output, "get")
    addstring(output, "enc")
    addint(output, jnt)
    writewreplyport(writer, output, input)
    bottlestring(input, text)
    stringtoc(text)
end


function help(writer)
    text = YARP.newstring()
    input = YARP.portableStruct()
    YARP.bottleinit(input)
    output = YARP.portableStruct()
    YARP.bottleinit(output)
    addstring(output, "help")
    addstring(output, "more")
    writewreplyport(writer, output, input)
    bottlestring(input, text)
    stringtoc(text)
end

function setvel(writer, jnt, speed)
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
    stringtoc(text)
end

function setpos(writer, jnt, pos)
    ## FIXME: Can be sped-up if needed
    text = YARP.newstring()
    input = YARP.portableStruct()
    YARP.bottleinit(input)
    output = YARP.portableStruct()
    YARP.bottleinit(output)
    addstring(output, "set")
    addstring(output, "pos")
    addint(output, jnt)
    adddouble(output, pos)
    writewreplyport(writer, output, input)
    bottlestring(input, text)
    stringtoc(text)
end

end ## module
