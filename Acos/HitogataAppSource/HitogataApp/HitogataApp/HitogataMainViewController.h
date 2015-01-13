//
//  HitogataMainViewController.h
//  HitogataApp
//
//

#import <GameKit/GameKit.h>
#import <UIKit/UIKit.h>

#define LED_TIMER_INTERVAL 0.05f
#define CHECK_SENSOR_INTERVAL 0.5f
#define I2C_SLEEP_INTERVAL 0.1f

#define I2C_WAIT_INTERVAL_LONG 0.5f

#define ACCELERATION_SENSOR_ADDRESS 0x1D
#define THRESH_ACT                  0x24
#define ACT_INACT_CTL               0x27
#define POWER_CONTROL_REGISTER      0x2D
#define INT_ENABLE                  0x2E
#define INT_SOURCE                  0x30
#define DATA_FORMAT                 0x31
#define X_AXIS_DATA_0               0x32
#define X_AXIS_DATA_1               0x33
#define Y_AXIS_DATA_0               0x34
#define Y_AXIS_DATA_1               0x35
#define Z_AXIS_DATA_0               0x36
#define Z_AXIS_DATA_1               0x37
#define TEMPERATURE_SENSOR_ADDRESS  0x48

#define M_P31 PIO1
#define M_P00 PIO2

enum {
    NONE_SENSOR          = 0,
    ACCELERATION_SENSOR  = 1,
    PRESSURE_SENSOR      = 4,
};

enum {
    COLOR_RED     = 0,
    COLOR_GREEN   = 1,
    COLOR_BLUE    = 2,
    COLOR_YELLOW  = 3,
    COLOR_SKY     = 4,
    COLOR_PURPLE  = 5,
    COLOR_WHITE   = 6,
};

enum {
    CONDITION_LT = 0,
    CONDITION_GT = 1,
};

// By TecSol

// comand ID
#define INIT_ID             0x50
#define BASE_INFO           0x51
#define MEASURE_CONTROL     0x53
#define GET_MEASURE_DATA    0x54
#define MEASURE_DATA_NOTICE 0x57
#define GET_ACC_DATA        0x58

#define COMMAND_WAIT        0x00

// status
#define STATUS_OK           0x0
#define STATUS_CHECKSUM_NG  0xC
#define STATUS_ID_NG        0xD
#define STATUS_DEVICE_BUSY  0xE
#define STATUS_PARAMETER_NG 0xF

#define PARAM_MALE          0x1
#define PARAM_FEMALE        0x0
#define PARAM_MIN_AGE       5
#define PARAM_MAX_AGE       120
#define PARAM_MIN_WEIGHT    20
#define PARAM_MAX_WEIGHT    130
#define PARAM_MIN_HEIGHT    100
#define PARAM_MAX_HEIGHT    200
#define PARAM_MIN_AW        1
#define PARAM_MAX_AW        20

// ==== start For Acos =====
// initialyze request
typedef struct InitReq
{
    unsigned char ID;
    unsigned char MessageSize;
    unsigned char Status;
    unsigned char ChechSum;
} InitReq_t, *pInitReq_t;
InitReq_t InitReqInfo;

// initialyze response
typedef struct InitResp
{
    unsigned char ID;
    unsigned char MessageSize;
    unsigned char Status;
    unsigned char ChechSum;
} InitResp_t, *pInitResp_t;
InitResp_t InitRespInfo;

// base information
typedef struct BaseInfo
{
    unsigned char  Sex;
    unsigned char  Age;
    unsigned short Weight;
    unsigned char  Height;
    unsigned char  AWMETs;
} BaseInfo_t, *pBaseInfo_t;
BaseInfo_t BaseInfo;

// base information request
typedef struct BaseInfoReq
{
    InitReq_t  ReqInfoHeader;
    unsigned short Setinfo;
    BaseInfo_t Req;
} BaseInfoReq_t, *pBaseInfoReq_t;
BaseInfoReq_t BaseInfoReq;

// base information request
typedef struct BaseInfoResp
{
    InitResp_t RespInfoHeader;
    BaseInfo_t Resp;
} BaseInfoResp_t, *pBaseInfoResp_t;
BaseInfoResp_t BaseInfoResp;

// measure request
typedef struct MeasureReq
{
    InitReq_t  ReqInfoHeader;
    unsigned char Switch;
} MeasureReq_t, *pMeasureReq_t;
MeasureReq_t MeasureReq;

// measure response
typedef struct MeasureResp
{
    InitResp_t RespInfoHeader;
    unsigned char WorkStatus;
} MeasureResp_t, *pMeasureResp_t;
MeasureResp_t MeasureResp;

// measure data request
typedef struct MeasureDataReq
{
    InitReq_t  ReqInfoHeader;
    unsigned char DataClear;
} MeasureDataReq_t, *pMeasureDataReq_t;
MeasureDataReq_t MeasureDataReq;

// measure data base
typedef struct MeasureDataBase
{
    unsigned char Steps[3];
    unsigned char AW[3];
    unsigned char TotalCalories[3];
    unsigned char TrainingCalories[3];
    unsigned char TotalTime[2];
    unsigned char IntensityTrainingTime[2];
} MeasureDataBase_t, *pMeasureDataBase_t;

// measure data change notice
typedef struct MeasureDataChangeNotice
{
    InitResp_t RespInfoHeader;
    MeasureDataBase_t MeasureData;
} MeasureDataChangeNotice_t, *pMeasureDataChangeNotice_t;
MeasureDataChangeNotice_t MeasureDataChangeNotice;

// measure data response
typedef struct MeasureDataResp
{
    InitResp_t RespInfoHeader;
    MeasureDataBase_t MeasureData;
    unsigned char Reserved[4];
} MeasureDataResp_t, *pMeasureDataResp_t;
MeasureDataResp_t MeasureDataResp;

// acceleration data request
InitReq_t AccDataReq;

// acceleration asix information
typedef struct AsixInfo
{
    unsigned char X[2];
    unsigned char Y[2];
    unsigned char Z[2];
} AsixInfo_t, *pAsixInfo_t;

// acceleration data response
typedef struct AccDataResp
{
    InitResp_t RespInfoHeader;
    unsigned char AsixInfoNumber;
    AsixInfo_t AsixData[28];
} AccDataResp_t, *pAccDataResp_t;
AccDataResp_t AccDataResp;

// ==== end For Acos =====



@interface HitogataMainViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *devicePairingButton;
@property (weak, nonatomic) IBOutlet UILabel *sensorCondition;

- (IBAction)tapDevicePairing:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *settingButton;

// By Tecsol
// ********* Start ******************************
@property (weak, nonatomic) IBOutlet UILabel *AcosSteps;
@property (weak, nonatomic) IBOutlet UILabel *AcosAW;
@property (weak, nonatomic) IBOutlet UILabel *AcosTotalCalories;
@property (weak, nonatomic) IBOutlet UILabel *AcosTrainingCalories;

@property (weak, nonatomic) IBOutlet UITextField *UserAge;
@property (weak, nonatomic) IBOutlet UITextField *UserWeight;
@property (weak, nonatomic) IBOutlet UITextField *UserHeight;
@property (weak, nonatomic) IBOutlet UISegmentedControl *UserSex;
@property (weak, nonatomic) IBOutlet UITextField *UserAW;
@property (weak, nonatomic) IBOutlet UISegmentedControl *GetMeasureDataSC;

@property (weak, nonatomic) IBOutlet UIButton *StopButton;

@property (weak, nonatomic) IBOutlet UIButton *StartButton;
@property (weak, nonatomic) IBOutlet UIButton *CatchButton;

@property (weak, nonatomic) IBOutlet UIButton *ClearButton;



- (IBAction)UserStart:(id)sender;
- (IBAction)UserStop:(id)sender;
- (IBAction)GetDeviceData:(id)sender;
- (IBAction)ClearDeviceData:(id)sender;
// ****** end ******************

@end
