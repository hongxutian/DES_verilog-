#include "DES.h"

 /**
  * @brief  DES SPI模块初始化
  */
void DES_Init()
{
	SPI_InitTypeDef  SPI_InitStructure;
  GPIO_InitTypeDef GPIO_InitStructure;
	
	/* 使能SPI时钟 */
	DES_SPI_APBxClock_FUN ( DES_SPI_CLK, ENABLE );
	
	/* 使能SPI引脚相关的时钟 */
 	DES_SPI_CS_APBxClock_FUN ( DES_SPI_CS_CLK|DES_SPI_SCK_CLK|
																	DES_SPI_MISO_PIN|DES_SPI_MOSI_PIN, ENABLE );
	
	  /* 配置SPI的 CS引脚，普通IO即可 */
  GPIO_InitStructure.GPIO_Pin = DES_SPI_CS_PIN;
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(DES_SPI_CS_PORT, &GPIO_InitStructure);
	
	  /* 配置SPI的 SCK引脚*/
  GPIO_InitStructure.GPIO_Pin = DES_SPI_SCK_PIN;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init(DES_SPI_SCK_PORT, &GPIO_InitStructure);
	
	/* 配置SPI的 MISO引脚*/
  GPIO_InitStructure.GPIO_Pin = DES_SPI_MISO_PIN;
  GPIO_Init(DES_SPI_MISO_PORT, &GPIO_InitStructure);

  /* 配置SPI的 MOSI引脚*/
  GPIO_InitStructure.GPIO_Pin = DES_SPI_MOSI_PIN;
  GPIO_Init(DES_SPI_MOSI_PORT, &GPIO_InitStructure);
	
	/* SPI 模式配置 */
  SPI_InitStructure.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
  SPI_InitStructure.SPI_Mode = SPI_Mode_Master;
  SPI_InitStructure.SPI_DataSize = SPI_DataSize_8b;
  SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;
  SPI_InitStructure.SPI_CPHA = SPI_CPHA_2Edge;
  SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
  SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_4;
  SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_LSB;
  SPI_InitStructure.SPI_CRCPolynomial = 7;
  SPI_Init(DES_SPIx , &SPI_InitStructure);

  /* 使能 SPI  */
  SPI_Cmd(DES_SPIx , ENABLE);
	
	DES_uncheck();
	
}

 /**
  * @brief  主从机交换一个字节数据
	* @param  data 发送的数据
  * @retval 接收的数据
  */
uint8_t DES_sendbyte(uint8_t data)
{
  /* 等待发送缓冲区为空，TXE事件 */
  while (SPI_I2S_GetFlagStatus(DES_SPIx , SPI_I2S_FLAG_TXE) == RESET)
	{
    
  }

  /* 写入数据寄存器，把要写入的数据写入发送缓冲区 */
  SPI_I2S_SendData(DES_SPIx , data);

  /* 等待接收缓冲区非空，RXNE事件 */
  while (SPI_I2S_GetFlagStatus(DES_SPIx , SPI_I2S_FLAG_RXNE) == RESET)
  {
   
  }
  /* 读取数据寄存器，获取接收缓冲区数据 */
  return SPI_I2S_ReceiveData(DES_SPIx );
}

 /**
  * @brief  DES加密
  * @param  desctx DES相关参数
	* @param  datalen 待加密数据的长度
	* @param  data	待加密的数据
	* @param  reslen 加密后的数据长度
	* @param  res	加密后的数据
  * @retval 结果代码，0成功
  */
char DES_encrypt(struct DES_context desctx,uint32_t datalen,uint8_t *data,uint32_t *reslen,uint8_t *res)
{
	char statucs_code = 0;
	uint32_t i;
	uint8_t temp;
	uint8_t valid = 0;
	uint32_t rl=0;
	
	DES_check();//选中模块开始通信
	//发送参数
	if(desctx.mode == DES_Mode_ECB)
	{
		DES_sendbyte(0x11);
		DES_sendbyte(desctx.padding);
		for(i=0;i<8;i++)
		{
			DES_sendbyte(desctx.key[i]);
		}
		DES_sendbyte(datalen>>24);
		DES_sendbyte(datalen>>16);
		DES_sendbyte(datalen>>8);
		DES_sendbyte(datalen);
	}else if(desctx.mode == DES_Mode_CBC)
	{
		DES_sendbyte(0x21);
		DES_sendbyte(desctx.padding);
		for(i=0;i<8;i++)
		{
			DES_sendbyte(desctx.key[i]);
		}
		for(i=0;i<8;i++)
		{
			DES_sendbyte(desctx.vec[i]);
		}
		DES_sendbyte(datalen>>24);
		DES_sendbyte(datalen>>16);
		DES_sendbyte(datalen>>8);
		DES_sendbyte(datalen);
	}
	i = 0;
	while(1)
	{
		if(i<datalen)
		{
			temp = DES_sendbyte(data[i]);
			i++;
		}else
		{
			temp = DES_sendbyte(0xff);
		}
		
		if(valid == 0)
		{
			if(temp == 0x01)
			{
				valid = 1;
			}
		}else 
		{
			res[rl++] = temp;
		}
		
		if(rl > datalen && (rl % 8) == 0)
		{
			break;
		}
	}
	
	*reslen = rl;
	
	DES_uncheck();//取消选中模块
	return statucs_code;
	
}

 /**
  * @brief  DES解密
  * @param  desctx DES相关参数
	* @param  datalen 待解密数据的长度
	* @param  data	待解密的数据
	* @param  reslen 解密后的数据长度
	* @param  res	解密后的数据
  * @retval 结果代码，0成功
  */
char DES_decrypt(struct DES_context desctx,uint32_t datalen,uint8_t *data,uint32_t *reslen,uint8_t *res)
{
	char statucs_code = 0;
	uint32_t i;
	uint8_t temp;
	uint8_t valid = 0;
	uint32_t rl=0;
	
	DES_check();//选中模块开始通信
	//发送参数
	if(desctx.mode == DES_Mode_ECB)
	{
		DES_sendbyte(0x12);
		DES_sendbyte(desctx.padding);
		for(i=0;i<8;i++)
		{
			DES_sendbyte(desctx.key[i]);
		}
		DES_sendbyte(datalen>>24);
		DES_sendbyte(datalen>>16);
		DES_sendbyte(datalen>>8);
		DES_sendbyte(datalen);
	}else if(desctx.mode == DES_Mode_CBC)
	{
		DES_sendbyte(0x22);
		DES_sendbyte(desctx.padding);
		for(i=0;i<8;i++)
		{
			DES_sendbyte(desctx.key[i]);
		}
		for(i=0;i<8;i++)
		{
			DES_sendbyte(desctx.vec[i]);
		}
		DES_sendbyte(datalen>>24);
		DES_sendbyte(datalen>>16);
		DES_sendbyte(datalen>>8);
		DES_sendbyte(datalen);
	}
	//发送数据
	i = 0;
	while(rl < datalen)
	{
		if(i<datalen)
		{
			temp = DES_sendbyte(data[i]);
			i++;
		}else
		{
			temp = DES_sendbyte(0xff);
		}
		
		if(valid == 0)
		{
			if(temp == 0x01)
			{
				valid = 1;
			}
		}else 
		{
			res[rl++] = temp;
		}
		
	}
	//等待处理结束
	for(i = 0;i < 8;i++)
	{
		if(res[rl - 1] != 0xff)
		{
			break;
		}
		rl--;
	}
	*reslen = rl;
	
	DES_uncheck();
	return statucs_code;
	
}
////测试的例子
//void tes()
//{
//	struct DES_context desctx;//存储DES相关的参数
//	uint8_t key[8] = "01234567";//密钥
//	uint8_t vec[8] = "01234567";//CBC需要的偏移量
//	
//	char data[128] = "hello world!";//待加密的数据
//	char res[128] ;//存储结果
//	uint32_t reslen;//存储结果的长度


//	DES_Init();
//	
//	desctx.mode = DES_Mode_ECB;//设置为ECB模式
//	desctx.padding = DES_Pkcs7padding;//设置数据填充模式
//	desctx.key = key;//设置密钥
////	desctx.vec = vec;//设置偏移量，ECB模式不需要
//	DES_encrypt(desctx,12,data,&reslen,res);//ECB 加密
//	
//}
