#include "os.h"

#define DELAY 1000

void user_task0(void)
{
	while (1) {
		uart_puts("Task 0: Running...\n");
		task_delay(DELAY);
		task_yield();
	}
}

void user_task1(void)
{
	uart_puts("Task 1: Created!\n");
	while (1) {
		uart_puts("Task 1: Running...\n");
		task_delay(DELAY);
		task_yield();
	}
}

/* NOTICE: DON'T LOOP INFINITELY IN main() */
void os_main(void)
{
	int res = 0;
	res = task_create(user_task0);
	if (res == 0)
		uart_puts("Task 0: Created!\n");
	
	res = task_create(user_task1);
	if (res == 0)
		uart_puts("Task 1: Created!\n");
}

