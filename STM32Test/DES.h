#ifndef _DES_H
#define _DES_H

#include "stm32f10x.h"


/*DES SPI接口定义-开头****************************/
#define      DES_SPIx                        SPI1
#define      DES_SPI_APBxClock_FUN          RCC_APB2PeriphClockCmd
#define      DES_SPI_CLK                     RCC_APB2Periph_SPI1

//CS(NSS)引脚 片选选普通GPIO即可
#define      DES_SPI_CS_APBxClock_FUN       RCC_APB2PeriphClockCmd
#define      DES_SPI_CS_CLK                  RCC_APB2Periph_GPIOC    
#define      DES_SPI_CS_PORT                 GPIOC
#define      DES_SPI_CS_PIN                  GPIO_Pin_0

//SCK引脚
#define      DES_SPI_SCK_APBxClock_FUN      RCC_APB2PeriphClockCmd
#define      DES_SPI_SCK_CLK                 RCC_APB2Periph_GPIOA   
#define      DES_SPI_SCK_PORT                GPIOA   
#define      DES_SPI_SCK_PIN                 GPIO_Pin_5
//MISO引脚
#define      DES_SPI_MISO_APBxClock_FUN     RCC_APB2PeriphClockCmd
#define      DES_SPI_MISO_CLK                RCC_APB2Periph_GPIOA    
#define      DES_SPI_MISO_PORT               GPIOA 
#define      DES_SPI_MISO_PIN                GPIO_Pin_6
//MOSI引脚
#define      DES_SPI_MOSI_APBxClock_FUN     RCC_APB2PeriphClockCmd
#define      DES_SPI_MOSI_CLK                RCC_APB2Periph_GPIOA    
#define      DES_SPI_MOSI_PORT               GPIOA 
#define      DES_SPI_MOSI_PIN                GPIO_Pin_7

#define			 DES_check()											GPIO_ResetBits( DES_SPI_CS_PORT, DES_SPI_CS_PIN )
#define			 DES_uncheck()										GPIO_SetBits( DES_SPI_CS_PORT, DES_SPI_CS_PIN )

#define 		 DES_Mode_ECB											0x01
#define 		 DES_Mode_CBC											0x02

#define 		 DES_Zeropadding									0x01
#define 		 DES_Pkcs7padding									0x02


struct DES_context
{
	uint8_t mode;//0x1 ECB 0x2 CBC
	uint8_t padding;//数据填充模式，0x01 zeropadding，0x02 pkcs7padding
	uint8_t * key;//密钥8字节
	uint8_t * vec;//偏移量8字节
};


void DES_Init();

char DES_encrypt(struct DES_context desctx,uint32_t datalen,uint8_t *data,uint32_t *reslen,uint8_t *res);
char DES_decrypt(struct DES_context desctx,uint32_t datalen,uint8_t *data,uint32_t *reslen,uint8_t *res);

#endif