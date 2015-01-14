//
//  HitogataMainViewController.m
//  HitogataApp
//
//

#import "HitogataMainViewController.h"
#import "Konashi.h"

@interface HitogataMainViewController ()

@end

@implementation HitogataMainViewController


int konashiSuccess;
NSTimer *checkSensorTimer;
int CommandID;
bool CheckCommandSend;
bool CommandBusy;
int CommandCount;
unsigned char MeasureControlFlag;
unsigned char GetMeasureDataFlag;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Konashi initialize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    _settingButton.hidden = YES;
    
    _StartButton.enabled = NO;
    _StopButton.enabled = NO;
    _CatchButton.enabled = NO;
    _ClearButton.enabled = NO;
    
    
    _UserAge.text = [NSString stringWithFormat:@"10"];
    _UserAge.keyboardType = UIKeyboardTypeDefault;
    
    _UserWeight.text = [NSString stringWithFormat:@"123"];
    _UserWeight.keyboardType = UIKeyboardTypeDefault;

    _UserHeight.text = [NSString stringWithFormat:@"160"];
    _UserHeight.keyboardType = UIKeyboardTypeDefault;

    _UserAW.text = [NSString stringWithFormat:@"3.2"];
    _UserAW.keyboardType = UIKeyboardTypeDefault;
    
    _AcosSteps.backgroundColor = [UIColor whiteColor];
    _AcosAW.backgroundColor = [UIColor whiteColor];
    _AcosTotalCalories.backgroundColor = [UIColor whiteColor];
    _AcosTrainingCalories.backgroundColor = [UIColor whiteColor];
}

#pragma mark -
#pragma mark - Konashi-iPhone Pairing

- (IBAction)tapDevicePairing:(id)sender
{
    if(![Konashi isConnected])
    {
        [Konashi addObserver:self selector:@selector(konashiNotFound) name:KONASHI_EVENT_PERIPHERAL_NOT_FOUND];
        [Konashi addObserver:self selector:@selector(konashiIsReady) name:KONASHI_EVENT_READY];
        [Konashi addObserver:self selector:@selector(konashiFindCanceled) name:KONASHI_EVENT_NO_PERIPHERALS_AVAILABLE];
        [Konashi find];
    }
    else
    {
        [Konashi addObserver:self selector:@selector(konashiIsDisconnected) name:KONASHI_EVENT_DISCONNECTED];
        [Konashi disconnect];
    }
}

- (void)konashiNotFound
{
    [Konashi removeObserver:self];
}

- (void)konashiFindCanceled
{
    [Konashi removeObserver:self];
}

- (void)konashiIsDisconnected
{
    _StartButton.enabled = NO;
    _StopButton.enabled = NO;
    _CatchButton.enabled = NO;
    _ClearButton.enabled = NO;
    
    [Konashi removeObserver:self];
    
    [_devicePairingButton setTitle:@"connect" forState:UIControlStateNormal];
    [[_devicePairingButton layer] setBackgroundColor:[[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] CGColor]];
    [_sensorCondition setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
    
    [self stopCheckSensor];
}

- (void)konashiIsReady
{
    [Konashi removeObserver:self];
    
    [_devicePairingButton setTitle:@"disconnect" forState:UIControlStateNormal];
    [[_devicePairingButton layer] setBackgroundColor:[[UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0] CGColor]];
    
    //Konash I/O setting
    [Konashi pinModeAll:0x0E];

    [Konashi digitalWriteAll:0x0E];

    [Konashi uartBaudrate:KONASHI_UART_RATE_9K6];
    [Konashi uartMode:KONASHI_UART_ENABLE];
    
    [self startCheckSensor];
}

#pragma mark - Konashi Input Control

- (void)startCheckSensor
{
    NSLog(@"Start check sensor.");

    CommandID = INIT_ID;
    CommandBusy = NO;
    CommandCount = 0;
    CheckCommandSend = NO;
    MeasureControlFlag = 0;
    GetMeasureDataFlag = 0;
    
    _StartButton.enabled = YES;
    _StopButton.enabled = NO;
    _CatchButton.enabled = NO;
    _ClearButton.enabled = NO;
    
    
    [Konashi addObserver:self selector:@selector(uartRead) name:KONASHI_EVENT_UART_RX_COMPLETE];

    checkSensorTimer = [NSTimer scheduledTimerWithTimeInterval:I2C_SLEEP_INTERVAL
                                                        target:self
                                                        selector:@selector(checkSensor:)
                                                        userInfo:nil
                                                        repeats:YES];
}

- (void)stopCheckSensor
{
    [Konashi removeObserver:self];
    if([checkSensorTimer isValid]) [checkSensorTimer invalidate];
}

- (void)checkSensor:(NSTimer *)timer
{
    if (CheckCommandSend == YES) { return; }
    
    //CheckCommandSend = YES;
    _AcosSteps.backgroundColor = [UIColor whiteColor];
    _AcosAW.backgroundColor = [UIColor whiteColor];
    _AcosTotalCalories.backgroundColor = [UIColor whiteColor];
    _AcosTrainingCalories.backgroundColor = [UIColor whiteColor];
    
    if (CommandID == INIT_ID) {
        // initialyze
        [self InitInfoSend];
    }
    else if (CommandID == BASE_INFO) {
      [self BaseInfoSend];
    }
    else if (CommandID == MEASURE_CONTROL) {
        [self MeasureControl:MeasureControlFlag];
    }
    else if (CommandID == GET_MEASURE_DATA) {
        [self GetMeasureData:GetMeasureDataFlag];
    }
    
    CheckCommandSend = YES;
    CommandBusy = NO;
    
    NSLog(@"  ---test111--- CommandStatus = %X", CommandID);
    
    [NSThread sleepForTimeInterval:1.0];
}

- (IBAction)UserStart:(id)sender
{
    //[self BaseInfoSend];
    MeasureControlFlag = 1;
    CommandID = BASE_INFO;
    CheckCommandSend = NO;
    
    _UserSex.enabled = NO;
    
    _UserAge.enabled = NO;
    _UserAge.borderStyle = UITextBorderStyleNone;
    _UserWeight.enabled = NO;
    _UserWeight.borderStyle = UITextBorderStyleNone;
    _UserHeight.enabled = NO;
    _UserHeight.borderStyle = UITextBorderStyleNone;
    _UserAW.enabled = NO;
    _UserAW.borderStyle = UITextBorderStyleNone;
}

- (IBAction)UserStop:(id)sender
{
    //[self BaseInfoSend];
    MeasureControlFlag = 0;
    CommandID = MEASURE_CONTROL;
    CheckCommandSend = NO;

    _UserSex.enabled = YES;

    _UserAge.enabled = YES;
    _UserAge.borderStyle = UITextBorderStyleRoundedRect;
    _UserAge.backgroundColor = [UIColor whiteColor];
    _UserWeight.enabled = YES;
    _UserWeight.borderStyle = UITextBorderStyleRoundedRect;
    _UserWeight.backgroundColor = [UIColor whiteColor];
    _UserHeight.enabled = YES;
    _UserHeight.borderStyle = UITextBorderStyleRoundedRect;
    _UserHeight.backgroundColor = [UIColor whiteColor];
    _UserAW.enabled = YES;
    _UserAW.borderStyle = UITextBorderStyleRoundedRect;
    _UserAW.backgroundColor = [UIColor whiteColor];
}

- (IBAction)GetDeviceData:(id)sender
{
    GetMeasureDataFlag = 0;
    CommandID = GET_MEASURE_DATA;
    CheckCommandSend = NO;
}
- (IBAction)ClearDeviceData:(id)sender
{
    GetMeasureDataFlag = 1;
    CommandID = GET_MEASURE_DATA;
    CheckCommandSend = NO;
}

- (void)GetCheckSum:(unsigned char *)pData Size:(int)size CheckSum:(unsigned char *)pCheckSum
{
    int i;
    unsigned int Total = 0;
    
    for (i = 0; i < size; i ++) {
        if (i == 3) continue;
        Total += *(pData + i);
    }
    *pCheckSum = (unsigned char)(~Total + 1);
}

- (void)UartWrite:(unsigned char *)pData Size:(int)size
{
    int i;
    int ret;
    unsigned char Temp;
    
    [Konashi digitalWrite:M_P00 value:HIGH];
    [Konashi digitalWrite:M_P31 value:LOW];
    
    for (i = 0; i < size; i ++) {
        Temp = *(pData + i);
        NSLog(@"UartTx %x", Temp);
        ret = [Konashi uartWrite:*(pData + i)];
    }

    [NSThread sleepForTimeInterval:0.1];
    [Konashi digitalWrite:M_P31 value:HIGH];
    [Konashi digitalWrite:M_P00 value:LOW];
}

- (void)uartRead // read uart information
{
    unsigned int TempSize, TempNum = 0;
    unsigned char RespData = [Konashi uartRead];
    
    NSLog(@"UartRx %x", RespData);

    //[NSThread sleepForTimeInterval:0.01];
    [Konashi digitalWrite:M_P31 value:HIGH];
    [Konashi digitalWrite:M_P00 value:HIGH];
 
    _AcosSteps.backgroundColor = [UIColor yellowColor];
    _AcosAW.backgroundColor = [UIColor yellowColor];
    _AcosTotalCalories.backgroundColor = [UIColor yellowColor];
    _AcosTrainingCalories.backgroundColor = [UIColor yellowColor];
   
    
    if (CommandBusy == NO) {
        if (CommandID == RespData) {
            CommandBusy = YES;
        }
        
        if (CheckCommandSend == YES) {
            if (RespData == MEASURE_DATA_NOTICE) {
                CommandID = MEASURE_DATA_NOTICE;
                CommandCount = sizeof(MeasureDataChangeNotice_t) - 1;
            }
        }
        
        if (CommandID == INIT_ID) {
            InitRespInfo.ID = INIT_ID;
            CommandCount = sizeof(InitResp_t) - 1;
        }
        else if (CommandID == BASE_INFO) {
            BaseInfoResp.RespInfoHeader.ID = BASE_INFO;
            CommandCount = sizeof(BaseInfoResp_t) - 1;
        }
        else if (CommandID == MEASURE_CONTROL) {
            MeasureResp.RespInfoHeader.ID = MEASURE_CONTROL;
            CommandCount = sizeof(MeasureResp_t) - 1;
        }
        else if (CommandID == GET_MEASURE_DATA) {
            MeasureDataResp.RespInfoHeader.ID = GET_MEASURE_DATA;
            CommandCount = sizeof(MeasureDataResp_t) - 1;
        }
        else if (CommandID == GET_ACC_DATA) {
            AccDataResp.RespInfoHeader.ID = GET_ACC_DATA;
            CommandCount = sizeof(AccDataResp_t) - 1;
        }
        else {
            NSLog(@"--- No surport --- !!");
        }
        //NSLog(@"RC %x", CommandID);
    }
    else {
        if (CommandID == INIT_ID) {
            TempSize = sizeof(InitResp_t);
            if (CommandCount == TempSize - 1) {
                InitRespInfo.MessageSize = RespData;
            }
            else if (CommandCount == TempSize - 2) {
                InitRespInfo.Status = RespData;
            }
            else if (CommandCount == TempSize - 3) {
                InitRespInfo.ChechSum = RespData;
            }
        }
        else if (CommandID == BASE_INFO) {
            TempSize = sizeof(BaseInfoResp_t);
            if (CommandCount == TempSize - 1) {
                BaseInfoResp.RespInfoHeader.MessageSize = RespData;
            }
            else if (CommandCount == TempSize - 2) {
                BaseInfoResp.RespInfoHeader.Status = RespData;
            }
            else if (CommandCount == TempSize - 3) {
                BaseInfoResp.RespInfoHeader.ChechSum = RespData;
            }
            else if (CommandCount == TempSize - 4) {
                BaseInfoResp.Resp.Sex = RespData & 0x01;
                //NSLog(@"BaseInfoResp.Resp.Sex %x", BaseInfoResp.Resp.Sex);

            }
            else if (CommandCount == TempSize - 5) {
                BaseInfoResp.Resp.Age = RespData;
            }
            else if (CommandCount == TempSize - 6) {
                BaseInfoResp.Resp.Weight = (unsigned short)RespData;
            }
            else if (CommandCount == TempSize - 7) {
                BaseInfoResp.Resp.Weight = BaseInfoResp.Resp.Weight << 8;
                BaseInfoResp.Resp.Weight |= (unsigned short)RespData;
            }
            else if (CommandCount == TempSize - 8) {
                BaseInfoResp.Resp.Height = RespData;
            }
            else if (CommandCount == TempSize - 9) {
                BaseInfoResp.Resp.AWMETs = RespData;
                CommandID = MEASURE_CONTROL;
                CheckCommandSend = NO;
            }
        }
        else if (CommandID == MEASURE_CONTROL) {
            TempSize = sizeof(MeasureResp_t);
           if (CommandCount == TempSize - 1) {
                MeasureResp.RespInfoHeader.MessageSize = RespData;
            }
            else if (CommandCount == TempSize - 2) {
                MeasureResp.RespInfoHeader.Status = RespData;
            }
            else if (CommandCount == TempSize - 3) {
                MeasureResp.RespInfoHeader.ChechSum = RespData;
            }
            else if (CommandCount == TempSize - 4) {
                MeasureResp.WorkStatus = RespData;
                if (MeasureControlFlag != 0) {
                    if (GetMeasureDataFlag == 0) {
                        CommandID = GET_MEASURE_DATA;
                        CheckCommandSend = NO;
                    }
                    _StartButton.enabled = NO;
                    _StopButton.enabled = YES;
                    _CatchButton.enabled = YES;
                    _ClearButton.enabled = YES;
                }
                else {
                    _StartButton.enabled = YES;
                    _StopButton.enabled = NO;
                    _CatchButton.enabled = NO;
                    _ClearButton.enabled = NO;
                }
            }
        }
        else if ((CommandID == GET_MEASURE_DATA) || (CommandID == MEASURE_DATA_NOTICE)){
            if (CommandID == MEASURE_DATA_NOTICE) {
                TempSize = sizeof(MeasureDataChangeNotice_t);
            }
            else {
                TempSize = sizeof(MeasureDataResp_t);
            }
            
            if (CommandCount == TempSize - 1) {
                MeasureDataResp.RespInfoHeader.MessageSize = RespData;
            }
            else if (CommandCount == TempSize - 2) {
                MeasureDataResp.RespInfoHeader.Status = RespData;
            }
            else if (CommandCount == TempSize - 3) {
                MeasureDataResp.RespInfoHeader.ChechSum = RespData;
            }
            else if (CommandCount == TempSize - 4) {
                MeasureDataResp.MeasureData.Steps[0] = RespData;
            }
            else if (CommandCount == TempSize - 5) {
                MeasureDataResp.MeasureData.Steps[1] = RespData;
            }
            else if (CommandCount == TempSize - 6) {
                MeasureDataResp.MeasureData.Steps[2] = RespData;
                TempNum |= MeasureDataResp.MeasureData.Steps[2];
                TempNum <<= 8;
                TempNum |= MeasureDataResp.MeasureData.Steps[1];
                TempNum <<= 8;
                TempNum |= MeasureDataResp.MeasureData.Steps[0];
                _AcosSteps.text = [NSString stringWithFormat:@"%d", TempNum];
            }
            else if (CommandCount == TempSize - 7) {
                MeasureDataResp.MeasureData.AW[0] = RespData;
            }
            else if (CommandCount == TempSize - 8) {
                MeasureDataResp.MeasureData.AW[1] = RespData;
            }
            else if (CommandCount == TempSize - 9) {
                MeasureDataResp.MeasureData.AW[2] = RespData;
                TempNum |= MeasureDataResp.MeasureData.AW[2];
                TempNum <<= 8;
                TempNum |= MeasureDataResp.MeasureData.AW[1];
                TempNum <<= 8;
                TempNum |= MeasureDataResp.MeasureData.AW[0];
                _AcosAW.text = [NSString stringWithFormat:@"%d", TempNum];
            }
            else if (CommandCount == TempSize - 10) {
                MeasureDataResp.MeasureData.TotalCalories[0] = RespData;
            }
            else if (CommandCount == TempSize - 11) {
                MeasureDataResp.MeasureData.TotalCalories[1] = RespData;
            }
            else if (CommandCount == TempSize - 12) {
                MeasureDataResp.MeasureData.TotalCalories[2] = RespData;
                TempNum |= MeasureDataResp.MeasureData.TotalCalories[2];
                TempNum <<= 8;
                TempNum |= MeasureDataResp.MeasureData.TotalCalories[1];
                TempNum <<= 8;
                TempNum |= MeasureDataResp.MeasureData.TotalCalories[0];
                _AcosTotalCalories.text = [NSString stringWithFormat:@"%.1f", (float)TempNum / 10];
            }
            else if (CommandCount == TempSize - 13) {
                MeasureDataResp.MeasureData.TrainingCalories[0] = RespData;
            }
            else if (CommandCount == TempSize - 14) {
                MeasureDataResp.MeasureData.TrainingCalories[1] = RespData;
                TempNum |= MeasureDataResp.MeasureData.TrainingCalories[1];
                TempNum <<= 8;
                TempNum |= MeasureDataResp.MeasureData.TrainingCalories[0];
                _AcosTrainingCalories.text = [NSString stringWithFormat:@"%.1f", (float)TempNum / 10];
            }
            else if (CommandCount == TempSize - 15) {
                MeasureDataResp.MeasureData.TrainingCalories[2] = RespData;
            }
            else if (CommandCount == TempSize - 16) {
                MeasureDataResp.MeasureData.TotalTime[0] = RespData;
                //NSLog(@"UartRx0 %x", RespData);
            }
            else if (CommandCount == TempSize - 17) {
                MeasureDataResp.MeasureData.TotalTime[1] = RespData;
                //NSLog(@"UartRx1 %x", RespData);
            }
            else if (CommandCount == TempSize - 18) {
                MeasureDataResp.MeasureData.IntensityTrainingTime[0] = RespData;
                //NSLog(@"UartRx2 %x", RespData);
            }
            else if (CommandCount == TempSize - 19) {
                MeasureDataResp.MeasureData.IntensityTrainingTime[1] = RespData;
                //NSLog(@"UartRx3 %x", RespData);
            }
        }
        else if (CommandID == GET_ACC_DATA) {
            // Not do it
        }
        else {
            NSLog(@"--- No surport --- !!");
        }

        CommandCount--;
        if (CommandCount == 0) {
            NSLog(@"--- CommandCount %x", CommandCount);
            CommandBusy = NO;
            //CheckCommandSend = NO;
        }
    }
}

- (void)InitInfoSend
{
    // initialyze
    InitReqInfo.ID = INIT_ID;
    InitReqInfo.MessageSize = sizeof(InitReq_t);
    InitReqInfo.Status = STATUS_OK;
    InitReqInfo.ChechSum = 0;
    
    //CommandCount = InitReqInfo.MessageSize;
    
    // get checksum
    [self GetCheckSum:(unsigned char *)&InitReqInfo Size:sizeof(InitReq_t) CheckSum:&InitReqInfo.ChechSum];
    
    [self UartWrite:(unsigned char *)&InitReqInfo Size:sizeof(InitReq_t)];
    
}
- (void)BaseInfoSend
{
    int Temp;
    
    //CheckCommandSend = NO;
    
    BaseInfoReq.ReqInfoHeader.ID = 0x51;
    BaseInfoReq.ReqInfoHeader.MessageSize = sizeof(BaseInfoReq_t);
    BaseInfoReq.ReqInfoHeader.Status = 0x00;
    
    BaseInfoReq.Setinfo = 0;
    
    if (_UserSex.selectedSegmentIndex == 0) {
        BaseInfoReq.Req.Sex = PARAM_MALE;
    }
    else if (_UserSex.selectedSegmentIndex == 1) {
        BaseInfoReq.Req.Sex = PARAM_FEMALE;
    }
    BaseInfoReq.Setinfo |= 0x0001;
    
    //NSLog(@"*** Sex %x *** !!", BaseInfoReq.Req.Sex);
    
    Temp = [_UserAge.text intValue];
    //NSLog(@"*** Age %x *** !!", Temp);
    if ((Temp >= PARAM_MIN_AGE) && (Temp <= PARAM_MAX_AGE)) {
        BaseInfoReq.Req.Age = (unsigned char)Temp;
        BaseInfoReq.Setinfo |= 0x0002;
    }
    else {
        BaseInfoReq.Req.Age = 0;
        BaseInfoReq.Setinfo |= 0x0000;
    }
    
    float WeightTemp;
    WeightTemp = [_UserWeight.text floatValue];
    
    Temp = (int)(WeightTemp * 10);
    
    if ((Temp >= (PARAM_MIN_WEIGHT * 10)) && (Temp <= (PARAM_MAX_WEIGHT * 10))) {
        BaseInfoReq.Req.Weight = ntohs((unsigned short)Temp);
        //NSLog(@"*** Weight %x *** !!", BaseInfoReq.Req.Weight);
        BaseInfoReq.Setinfo |= 0x0004;
    }
    else {
        BaseInfoReq.Req.Weight = 0;
        BaseInfoReq.Setinfo |= 0x0000;
    }
    
    Temp = [_UserHeight.text intValue];
    //NSLog(@"*** Height %x *** !!", Temp);
    if ((Temp >= PARAM_MIN_HEIGHT) && (Temp <= PARAM_MAX_HEIGHT)) {
        BaseInfoReq.Req.Height = (unsigned char)Temp;
        BaseInfoReq.Setinfo |= 0x0008;
    }
    else {
        BaseInfoReq.Req.Height = 0;
        BaseInfoReq.Setinfo |= 0x0000;
    }
    
    float AWTemp;
    AWTemp = [_UserAW.text floatValue];
    
    Temp = (int)(AWTemp * 10);
    //NSLog(@"*** AW %x *** !!", Temp);
    if ((Temp >= PARAM_MIN_AW * 10) && (Temp <= PARAM_MAX_AW * 10)) {
        BaseInfoReq.Req.AWMETs = (unsigned char)Temp;
        //NSLog(@"*** AW %x *** !!", Temp);
        BaseInfoReq.Setinfo |= 0x0010;
    }
    else {
        BaseInfoReq.Req.AWMETs = 0;
        BaseInfoReq.Setinfo |= 0x0000;
    }
    
    BaseInfoReq.Setinfo = ntohs(BaseInfoReq.Setinfo);
    //NSLog(@"*** BaseInfoReq.Setinfo %x *** !!", BaseInfoReq.Setinfo);
    
    // get checksum
    [self GetCheckSum:(unsigned char *)&BaseInfoReq Size:sizeof(BaseInfoReq_t) CheckSum:&BaseInfoReq.ReqInfoHeader.ChechSum];
    
    [self UartWrite:(unsigned char *)&BaseInfoReq Size:sizeof(BaseInfoReq_t)];
}

- (void)MeasureControl:(unsigned char)flag
{
    // initialyze
    MeasureReq.ReqInfoHeader.ID = MEASURE_CONTROL;
    MeasureReq.ReqInfoHeader.MessageSize = sizeof(MeasureReq_t);
    MeasureReq.ReqInfoHeader.Status = STATUS_OK;
    MeasureReq.ReqInfoHeader.ChechSum = 0;
    
    MeasureReq.Switch = flag;
    NSLog(@"*** MeasureReq.Switch %d  *** !!", MeasureReq.Switch);
    
    //CommandCount = InitReqInfo.MessageSize;
    
    // get checksum
    [self GetCheckSum:(unsigned char *)&MeasureReq Size:sizeof(MeasureReq_t) CheckSum:&MeasureReq.ReqInfoHeader.ChechSum];
    
    [self UartWrite:(unsigned char *)&MeasureReq Size:sizeof(MeasureReq_t)];
}

- (void)GetMeasureData:(unsigned char)flag
{
    // initialyze
    MeasureDataReq.ReqInfoHeader.ID = GET_MEASURE_DATA;
    MeasureDataReq.ReqInfoHeader.MessageSize = sizeof(MeasureDataReq_t);
    MeasureDataReq.ReqInfoHeader.Status = STATUS_OK;
    MeasureDataReq.ReqInfoHeader.ChechSum = 0;
    
    MeasureDataReq.DataClear = flag;
    
    // get checksum
    [self GetCheckSum:(unsigned char *)&MeasureDataReq Size:sizeof(MeasureDataReq_t) CheckSum:&MeasureDataReq.ReqInfoHeader.ChechSum];
    
    [self UartWrite:(unsigned char *)&MeasureDataReq Size:sizeof(MeasureDataReq_t)];
}

- (IBAction)UserSControl:(id)sender {
    NSLog(@"*** test sex 22 *** !!");
    if (_UserSex.selectedSegmentIndex == 0) {
        NSLog(@"*** Male *** !!");
    }
    else if (_UserSex.selectedSegmentIndex == 1) {
        NSLog(@"*** Female *** !!");
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_UserAge resignFirstResponder];
    [_UserAW resignFirstResponder];
    [_UserWeight resignFirstResponder];
    [_UserHeight resignFirstResponder];

    return YES;
}

@end
