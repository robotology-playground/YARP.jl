type networkStruct
    implementation::Ptr{Void}
    networkStruct() = new(C_NULL)
end
typealias writerStruct networkStruct
typealias readerStruct networkStruct
typealias contactStruct networkStruct
typealias portStruct networkStruct
typealias yarpstring networkStruct


type portableStruct
    client::Ptr{Void}
    implementation::Ptr{Void}
    adaptor::Ptr{Void}
    portableStruct() = new(C_NULL, C_NULL, C_NULL)
end

## int (*write) (yarpWriterPtr connection, void *client);
## int (*read) (yarpReaderPtr connection, void *client);
## int (*onCompletion)(void *client);
## int (*onCommencement)(void *cleint);
## void *unused1;
## void *unused2;
## void *unused3;
## void *unused4;


## type portableCallbackStruct
##     write::Int
## end
