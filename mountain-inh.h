#ifndef MOUNTAIN_INH_DEFINED_H
#define MOUNTAIN_INH_DEFINED_H


// This is written as C code (not C++)


typedef unsigned int uint;

// Linked List node
typedef struct LListNode
{
    void *val;
    struct LListNode *next;
} LListNode_t;

LListNode_t *ArrToLList(void **arr, unsigned len);
void **LListToArr(LListNode_t *list);
long LListLength(LListNode_t *list);

long longMin(long x, long y);
long longMax(long x, long y);
long longAbs(long x);

double doubleMin(double x, double y);
double doubleMax(double x, double y);
double doubleAbs(double x);

float floatMin(float x, float y);
float floatMax(float x, float y);
float floatAbs(float x);

int intMin(int x, int y);
int intMax(int x, int y);
int intAbs(int x);

uint uintMin(uint x, uint y);
uint uintMax(uint x, uint y);

float floatLinearInterpolate(float x, float x_min, float x_max, float ret_min, float ret_max);

uint stringEscape(char *str, unsigned len);

uint loadFile(const char *filename, char **text_out);

#ifdef MOUNTAIN_INH_IMPLEMENTATION

#include <stdlib.h>

long longMin(long x, long y) { return (x < y)? x : y; }
long longMax(long x, long y) { return (x > y)? x : y; }
long longAbs(long x) { return (x >= 0)? x : -x; }

double doubleMin(double x, double y) { return (x < y)? x : y; }
double doubleMax(double x, double y) { return (x > y)? x : y; }
double doubleAbs(double x) { return (x >= 0)? x : -x; }

float floatMin(float x, float y) { return (x < y)? x : y; }
float floatMax(float x, float y) { return (x > y)? x : y; }
float floatAbs(float x) { return (x >= 0)? x : -x; }

int intMin(int x, int y) { return (x < y)? x : y; }
int intMax(int x, int y) { return (x > y)? x : y; }
int intAbs(int x) { return (x >= 0)? x : -x; }

uint uintMin(uint x, uint y) { return (x < y)? x : y; }
uint uintMax(uint x, uint y) { return (x > y)? x : y; }

float floatLinearInterpolate(float x, float x_min, float x_max, float ret_min, float ret_max)
{
    return ret_min + (ret_max - ret_min) * ((x - x_min) / (x_max - x_min));
}

// Load all of the contents of a given file
// Return value: file size
uint loadFile(const char *filename, char **text_out)
{
    FILE *fp = fopen(filename, "rb");

    if (!fp) { return 0; }

    fseek(fp, 0, SEEK_END);
    uint len = ftell(fp);
    rewind(fp);

    char *text = malloc(len + 1);
    if (!text)
    {
        fclose(fp);
        return 0;
    }

    fread(text, 1, len, fp);
    text[len] = '\0';
    fclose(fp);

    *text_out = text;
    return len;
}

// Convert a linked list to an array
// (allocates a new array)
void **LListToArr(LListNode_t *list)
{
    long n = LListLength(list);
    void **p = malloc(n * sizeof(*p));
    for (unsigned i = 0; list; i++, list = list->next)
    {
        p[i] = list->val;
    }
    return p;
}

// Convert an array to a linked list
// (allocates a new linked list)
LListNode_t *ArrToLList(void **arr, unsigned len)
{
    if (!len) { return NULL; }
    LListNode_t *result = malloc(len * sizeof(LListNode_t));
    LListNode_t *p = result;
    for (unsigned i = 0; i < len; i++, p = p->next)
    {
        p->val = arr[i];
        p->next = p + 1;
    }
    return result;
}

// Get the length of a linked list
long LListLength(LListNode_t *list)
{
    long n = 0;
    while (list)
    {
        n++;
        list = list->next;
    }
    return n;
}

// Escape a string.
//   (or is this called "un-escaping"?)
// Converts escape sequences into the corresponding real ASCII
// values.
// Modifies the string in-place
unsigned stringEscape(char *str, unsigned len)
{
    if (!str || len <= 0) { return 0; }
    unsigned r = 0; // read index
    unsigned w = 0; // write index
    while (r < len && str[r])
    {
        char c = str[r];
        if (c == '\\')
        {
            r++;
            c = str[r];
            switch (c)
            {
                case 'e': // escape
                    c = '\x1b';
                    break;
                case 'a':
                    c = '\a';
                    break;
                case 'b':
                    c = '\b';
                    break;
                case 'n':
                    c = '\n';
                    break;
                case 'r':
                    c = '\r';
                    break;
                case 't':
                    c = '\t';
                    break;
                default:
                    // default result character is itself
                    break;
            }
        }
        str[w] = c;
        r++;
        w++;
    }
    str[w] = '\0';
    return w;
}



#endif /* INH_IMPLEMENTATION */

#endif /* MOUNTAIN_INH_DEFINED_H */
