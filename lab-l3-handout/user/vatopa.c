#include "kernel/types.h"
#include "user.h"

uint64 main(int argc, char *argv[])
{
    uint64 va = atoi(argv[1]);
    int id;

    if (argc != 2 && argc != 3)
    {
        printf("Usage: vatopa virtual_address [pid] \n", argv[0]);
        exit(1);
    }

    if (argc == 2)
    {

        id = getpid();
    }

    if (argc == 3)
    {
        id = atoi(argv[2]);
    }
    uint64 pa = va2pa(va, id);

    if (pa == 0)
    {
        printf("Error: virtual address is not valid \n");
    }
    else
    {

        printf("0x%x\n", pa);
    }

    exit(0);
}
