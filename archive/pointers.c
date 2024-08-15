#include <stdio.h>

int main(int argc, char *argv[])
{
    char letter = 'A';

    // char str[] = {'H', 'e', 'l', 'l', 'o', '\0'};

    // char *str = "Hello";

    char str[] = "Hello";

    // print the first letter of str
    printf("%c\n", *str);

    // print the second letter of str
    printf("%c\n", *(str + 1));

    // print the third letter of str
    printf("%c\n", *(str + 2));

    int numbers[] = {1, 2, 3};

    // print the first number
    printf("%d\n", *numbers);

    // print the second number
    printf("%d\n", *(numbers + 1));

    // print the third number
    printf("%d\n", *(numbers + 2));

    return 0;
}