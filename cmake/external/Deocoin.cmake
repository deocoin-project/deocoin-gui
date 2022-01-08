# Deocoin

set(Deocoin_CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
    -DBUILD_ALL:BOOL=FALSE) # Only libraries are required!

if(CMAKE_TOOLCHAIN_FILE)
    list(INSERT Deocoin_CMAKE_ARGS 0 -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
endif()

if(NOT WIN32)
    list(INSERT Deocoin_CMAKE_ARGS 0 -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE})
endif()

ExternalProject_Add(Deocoin
    GIT_REPOSITORY https://github.com/deocoin-project/deocoin.git
    GIT_TAG master
    GIT_SHALLOW ON
    GIT_PROGRESS OFF

    UPDATE_COMMAND ""
    PATCH_COMMAND ""

    CMAKE_ARGS ${Deocoin_CMAKE_ARGS}

    # CONFIGURE_COMMAND (use default)
    BUILD_COMMAND ${CMAKE_COMMAND} --build . --config ${CMAKE_BUILD_TYPE} --target DeocoinFramework
    BUILD_ALWAYS FALSE
    TEST_COMMAND ""
    INSTALL_COMMAND ""
)

ExternalProject_Get_property(Deocoin SOURCE_DIR)
ExternalProject_Get_property(Deocoin BINARY_DIR)

set(DeocoinFramework_INCLUDE_DIRS
    "${SOURCE_DIR}/include"
    "${SOURCE_DIR}/lib"
    "${BINARY_DIR}/lib"
    "${BINARY_DIR}/_ExternalProjects/Install/sparsehash/include"
)
if(MSVC)
    list(APPEND DeocoinFramework_INCLUDE_DIRS "${SOURCE_DIR}/lib/Platform/Windows")
    list(APPEND DeocoinFramework_INCLUDE_DIRS "${SOURCE_DIR}/lib/Platform/msc")
elseif(APPLE)
    list(APPEND DeocoinFramework_INCLUDE_DIRS "${SOURCE_DIR}/lib/Platform/OSX")
    list(APPEND DeocoinFramework_INCLUDE_DIRS "${SOURCE_DIR}/lib/Platform/Posix")
elseif(ANDROID)
    list(APPEND DeocoinFramework_INCLUDE_DIRS "${SOURCE_DIR}/lib/Platform/Android")
    list(APPEND DeocoinFramework_INCLUDE_DIRS "${SOURCE_DIR}/lib/Platform/Posix")
else()
    list(APPEND DeocoinFramework_INCLUDE_DIRS "${SOURCE_DIR}/lib/Platform/Linux")
    list(APPEND DeocoinFramework_INCLUDE_DIRS "${SOURCE_DIR}/lib/Platform/Posix")
endif()

set(DeocoinFramework_LIBS
    BlockchainExplorer
    Common
    Crypto
    CryptoNoteCore
    CryptoNoteProtocol
    Global
    Http
    InProcessNode
    JsonRpcServer
    Logging
    Mnemonics
    NodeRpcProxy
    P2p
    PaymentGate
    Rpc
    Serialization
    System
    Transfers
    Wallet
)

mark_as_advanced(DeocoinFramework_INCLUDE_DIRS DeocoinFramework_LIBS)

foreach(LIB ${DeocoinFramework_LIBS})
    set(LIB_IMPORTED_LOCATION_KEY "RELEASE")
    set(LIB_SUFFIX "")
    if (CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(LIB_IMPORTED_LOCATION_KEY "DEBUG")
        set(LIB_SUFFIX "d")
    endif()

    set(${LIB}_filename "${CMAKE_STATIC_LIBRARY_PREFIX}DeocoinFramework_${LIB}${LIB_SUFFIX}${CMAKE_STATIC_LIBRARY_SUFFIX}")
    if(WIN32)
        set(${LIB}_library "${BINARY_DIR}/lib/${CMAKE_BUILD_TYPE}/${${LIB}_filename}")
    else()
        set(${LIB}_library "${BINARY_DIR}/lib/${${LIB}_filename}")
    endif()

    add_library(DeocoinFramework::${LIB} UNKNOWN IMPORTED GLOBAL)
    set_target_properties(DeocoinFramework::${LIB} PROPERTIES
        IMPORTED_CONFIGURATIONS ${CMAKE_BUILD_TYPE}
        IMPORTED_LOCATION_${LIB_IMPORTED_LOCATION_KEY} ${${LIB}_library}
    )
    add_dependencies(DeocoinFramework::${LIB} Deocoin)
endforeach()

# DeocoinFramework::Common
target_link_libraries(DeocoinFramework::Common INTERFACE
    Threads::Threads
    DeocoinFramework::Crypto
    DeocoinFramework::Global
)
if(UNIX AND NOT ANDROID)
    target_link_libraries(DeocoinFramework::Common INTERFACE -lresolv)
endif()

# DeocoinFramework::CryptoNoteCore
target_link_libraries(DeocoinFramework::CryptoNoteCore INTERFACE
    Boost::filesystem
    Boost::program_options
    DeocoinFramework::BlockchainExplorer
    DeocoinFramework::Common
    DeocoinFramework::Crypto
    DeocoinFramework::Global
    DeocoinFramework::Logging
    DeocoinFramework::Serialization
)

# DeocoinFramework::Global
target_link_libraries(DeocoinFramework::Global INTERFACE 
    DeocoinFramework::Global
)

# DeocoinFramework::InProcessNode
target_link_libraries(DeocoinFramework::InProcessNode INTERFACE
    DeocoinFramework::BlockchainExplorer
    DeocoinFramework::Global
)

# DeocoinFramework::NodeRpcProxy
target_link_libraries(DeocoinFramework::NodeRpcProxy INTERFACE
    DeocoinFramework::Global
    DeocoinFramework::System
)

# DeocoinFramework::P2p
target_link_libraries(DeocoinFramework::P2p INTERFACE
    MiniUPnP::miniupnpc
    DeocoinFramework::CryptoNoteProtocol
    DeocoinFramework::Global
)

if(WIN32 AND MSVC)
    target_link_libraries(DeocoinFramework::P2p INTERFACE Bcrypt)
endif()

# DeocoinFramework::PaymentGate
target_link_libraries(DeocoinFramework::PaymentGate INTERFACE
    DeocoinFramework::JsonRpcServer
    DeocoinFramework::NodeRpcProxy
    DeocoinFramework::System
    DeocoinFramework::Wallet
)

# DeocoinFramework::Rpc
target_link_libraries(DeocoinFramework::Rpc INTERFACE
    DeocoinFramework::BlockchainExplorer
    DeocoinFramework::CryptoNoteCore
    DeocoinFramework::Global
    DeocoinFramework::P2p
    DeocoinFramework::PaymentGate
    DeocoinFramework::Serialization
    DeocoinFramework::System
    DeocoinFramework::Http
)

# DeocoinFramework::Serialization
target_link_libraries(DeocoinFramework::Serialization INTERFACE
    DeocoinFramework::Common
)

# DeocoinFramework::System
if(WIN32)
    target_link_libraries(DeocoinFramework::System INTERFACE ws2_32)
endif()

# DeocoinFramework::Transfers
target_link_libraries(DeocoinFramework::Transfers INTERFACE
    DeocoinFramework::CryptoNoteCore
    DeocoinFramework::Global
)

# DeocoinFramework::Wallet
target_link_libraries(DeocoinFramework::Wallet INTERFACE
    Boost::filesystem
    DeocoinFramework::Common
    DeocoinFramework::Crypto
    DeocoinFramework::CryptoNoteCore
    DeocoinFramework::Logging
    DeocoinFramework::Mnemonics
    DeocoinFramework::Rpc
    DeocoinFramework::Transfers
)

# MiniUPnP::miniupnpc

get_filename_component(MINIUPNP_DIR "${BINARY_DIR}/_ExternalProjects/Install/MiniUPnP" ABSOLUTE CACHE)
set(MINIUPNP_INCLUDE_DIRS "${MINIUPNP_DIR}/include")
set(MINIUPNP_STATIC_LIBRARY "${MINIUPNP_DIR}/lib/libminiupnpc${CMAKE_STATIC_LIBRARY_SUFFIX}")
mark_as_advanced(MINIUPNP_DIR MINIUPNP_INCLUDE_DIRS MINIUPNP_STATIC_LIBRARY)

add_library(MiniUPnP::miniupnpc STATIC IMPORTED GLOBAL)
add_dependencies(MiniUPnP::miniupnpc MiniUPnP)
set_target_properties(MiniUPnP::miniupnpc PROPERTIES
    IMPORTED_LOCATION "${MINIUPNP_STATIC_LIBRARY}"
    INTERFACE_COMPILE_DEFINITIONS "MINIUPNP_STATICLIB"
)
if(WIN32)
    target_link_libraries(MiniUPnP::miniupnpc INTERFACE iphlpapi mswsock ws2_32)
endif()
