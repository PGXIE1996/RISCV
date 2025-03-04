#include "os.h"

void plic_init(void)
{
	// 读取当前Hart值，在start.S中通过"mv tp, mhartid"将hartid保存在tp寄存器中
	int hart = r_tp();

	/*
	 * Set priority for UART0.
	 *
	 * Each PLIC interrupt source can be assigned a priority by writing
	 * to its 32-bit memory-mapped priority register.
	 * The QEMU-virt (the same as FU540-C000) supports 7 levels of priority.
	 * A priority value of 0 is reserved to mean "never interrupt" and
	 * effectively disables the interrupt.
	 * Priority 1 is the lowest active priority, and priority 7 is the highest.
	 * Ties between global interrupts of the same priority are broken by
	 * the Interrupt ID; interrupts with the lowest ID have the highest
	 * effective priority.
	 */
	*(uint32_t*)PLIC_PRIORITY(UART0_IRQ) = 1;  // 设置UART中断优先级为1

	/*
	 * Enable UART0
	 *
	 * Each global interrupt can be enabled by setting the corresponding
	 * bit in the enables registers.
	 */
	*(uint32_t*)PLIC_MENABLE(hart, UART0_IRQ) |= (1 << (UART0_IRQ % 32));  // 开启Hart的UART中断,每个Hart两个

	/*
	 * Set priority threshold for UART0.
	 *
	 * PLIC will mask all interrupts of a priority less than or equal to threshold.
	 * Maximum threshold is 7.
	 * For example, a threshold value of zero permits all interrupts with
	 * non-zero priority, whereas a value of 7 masks all interrupts.
	 * Notice, the threshold is global for PLIC, not for each interrupt source.
	 */
	*(uint32_t*)PLIC_MTHRESHOLD(hart) = 0;  // 定义中断阈值

	/* enable machine-mode external interrupts. */
	// #define MIE_MEIE (1 << 11) ：mie 用于启用或禁用特定类型的中断源。它是一个位掩码寄存器，每一位对应一种中断类型的使能状态。
	// 第7位就是外部中断（例如PLIC）控制
	w_mie(r_mie() | MIE_MEIE);

	/* enable machine-mode global interrupts. */
	// #define MSTATUS_MIE (1 << 3): 全局中断打开
	w_mstatus(r_mstatus() | MSTATUS_MIE);
}

/*
 * DESCRIPTION:
 *	Query the PLIC what interrupt we should serve.
 *	Perform an interrupt claim by reading the claim register, which
 *	returns the ID of the highest-priority pending interrupt or zero if there
 *	is no pending interrupt.
 *	A successful claim also atomically clears the corresponding pending bit
 *	on the interrupt source.
 * RETURN VALUE:
 *	the ID of the highest-priority pending interrupt or zero if there
 *	is no pending interrupt.
 */
int plic_claim(void)
{
	int hart = r_tp();
	int irq = *(uint32_t*)PLIC_MCLAIM(hart);
	return irq;
}

/*
 * DESCRIPTION:
  *	Writing the interrupt ID it received from the claim (irq) to the
 *	complete register would signal the PLIC we've served this IRQ.
 *	The PLIC does not check whether the completion ID is the same as the
 *	last claim ID for that target. If the completion ID does not match an
 *	interrupt source that is currently enabled for the target, the completion
 *	is silently ignored.
 * RETURN VALUE: none
 */
void plic_complete(int irq)
{
	int hart = r_tp();
	*(uint32_t*)PLIC_MCOMPLETE(hart) = irq;
}
