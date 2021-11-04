#include <opari2/pomp2_lib.h>

#define POMP2_DLIST_00001 shared(pomp2_region_1,pomp2_region_2)
static POMP2_Region_handle pomp2_region_1 = NULL;
static POMP2_Region_handle pomp2_region_2 = NULL;

void POMP2_Init_regions_1635171039380048_2()
{
    POMP2_Assign_handle( &pomp2_region_1, "129*regionType=parallel*sscl=/netfs/ei1922/marie_no/DNA/apm/src/apm.c:212:212*escl=/netfs/ei1922/marie_no/DNA/apm/src/apm.c:246:246**" );
    POMP2_Assign_handle( &pomp2_region_2, "159*regionType=for*sscl=/netfs/ei1922/marie_no/DNA/apm/src/apm.c:214:214*escl=/netfs/ei1922/marie_no/DNA/apm/src/apm.c:245:245*hasReduction=1*scheduleType=guided**" );
}
