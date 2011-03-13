SET(SRCS alpha.cpp
         clusterfit.cpp
         colourblock.cpp
         colourfit.cpp
         colourset.cpp
         maths.cpp
         rangefit.cpp
         singlecolourfit.cpp
         squish.cpp)

INCLUDE_DIRECTORIES(./)
ADD_LIBRARY(squish SHARED ${SRCS})
ADD_LIBRARY(squish_static STATIC ${SRCS})

SET_TARGET_PROPERTIES(squish_static PROPERTIES OUTPUT_NAME squish)

INSTALL(TARGETS squish
        LIBRARY DESTINATION lib)
INSTALL(TARGETS squish_static
        ARCHIVE DESTINATION lib)
INSTALL(FILES squish.h
        DESTINATION include) 
