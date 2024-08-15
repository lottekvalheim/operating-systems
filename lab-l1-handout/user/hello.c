#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    if (argc <= 1)
    {
        fprintf(1, "Hello World\n");
    }
    else if (argc > 1)
    {
        for (int i = 0; i < argc; i++)
        {
            if (i == 0)
            {
                fprintf(2, "Hello %s, nice to meet you!\n", argv[1]);
                continue;
            }
        }
    }
    lotte();

    return 0;
}
