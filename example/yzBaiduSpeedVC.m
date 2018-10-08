//
//  yzBaiduSpeedVC.m
//  DataSaveTest
//
//  Created by Mac on 2018/9/28.
//  Copyright © 2018年 Mac. All rights reserved.
//

#import "yzBaiduSpeedVC.h"
#import <BDSASRDefines.h>
#import <BDSASRParameters.h>
#import <BDSWakeupDefines.h>
#import <BDRecognizerViewController.h>
#import <BDSEventManager.h>

	//#error "请在官网新建应用，配置包名，并在此填写应用的 api key, secret key, appid(即appcode)"
const NSString* API_KEY = @"BPmC7Di55Q0OZIpfiepaSMdD";
const NSString* SECRET_KEY = @"36f93e7ddd973e5842fbc28ee8c79459";
const NSString* APP_ID = @"6810460";

@interface yzBaiduSpeedVC ()<BDSClientASRDelegate, BDSClientWakeupDelegate, BDRecognizerViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) BDSEventManager *asrEventManager;
@property (strong, nonatomic) BDSEventManager *wakeupEventManager;

@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@property(nonatomic, assign) BOOL continueToVR;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *startSpeedButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation yzBaiduSpeedVC

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.asrEventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
	[self.asrEventManager setDelegate:self] ;
	
	self.wakeupEventManager = [BDSEventManager createEventManagerWithName:BDS_WAKEUP_NAME];
	
	self.continueToVR = NO;
	
	
	[self configVoiceRecognitionClient];
	
}

#pragma mark - Private: Configuration

- (void)configVoiceRecognitionClient {
		//设置DEBUG_LOG的级别
	[self.asrEventManager setParameter:@(EVRDebugLogLevelTrace) forKey:BDS_ASR_DEBUG_LOG_LEVEL];
		//配置API_KEY 和 SECRET_KEY 和 APP_ID
	[self.asrEventManager setParameter:@[API_KEY, SECRET_KEY] forKey:BDS_ASR_API_SECRET_KEYS];
	[self.asrEventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
		//配置端点检测（二选一）
	[self configModelVAD];
		//      [self configDNNMFE];
	
		//     [self.asrEventManager setParameter:@"15361" forKey:BDS_ASR_PRODUCT_ID];
		// ---- 语义与标点 -----
	[self enableNLU];
		//    [self enablePunctuation];
		// ------------------------
}
- (void)configModelVAD {
	NSString *modelVAD_filepath = [[NSBundle mainBundle] pathForResource:@"/ASR/BDSClientEASRResources/bds_easr_basic_model" ofType:@"dat"];
	[self.asrEventManager setParameter:modelVAD_filepath forKey:BDS_ASR_MODEL_VAD_DAT_FILE];
	[self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_MODEL_VAD];
}
- (void) enableNLU {
		// ---- 开启语义理解 -----
	[self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_NLU];
	[self.asrEventManager setParameter:@"1536" forKey:BDS_ASR_PRODUCT_ID];
}



- (IBAction)backButtonClick:(UIButton *)sender {
	[self dismissViewControllerAnimated:YES completion:^{
		
	}];
}

- (IBAction)startSpeedClick:(UIButton *)sender {
	[self.asrEventManager sendCommand:BDS_WP_CMD_START];
	self.stopButton.enabled = YES;
	self.cancelButton.enabled = YES;
}

- (IBAction)stopSpeedClick:(UIButton *)sender {
	self.stopButton.enabled = NO;
	[self.asrEventManager sendCommand:BDS_ASR_CMD_STOP];
}

- (IBAction)cancelClick:(UIButton *)sender {
	self.stopButton.enabled = NO;
	self.cancelButton.enabled = NO;
	[self.asrEventManager sendCommand:BDS_ASR_CMD_CANCEL];
}

- (void)cleanLogUI
{
	self.resultTextView.text = @"";
	self.logTextView.text = @"";
}

- (void)printLogTextView:(NSString *)logString
{
	self.logTextView.text = [logString stringByAppendingString:_logTextView.text];
	[self.logTextView scrollRangeToVisible:NSMakeRange(0, 0)];
}

- (void)voiceRecogButtonHelper
{
		//    [self configFileHandler];
	[self.asrEventManager setDelegate:self];
	[self.asrEventManager setParameter:nil forKey:BDS_ASR_AUDIO_FILE_PATH];
	[self.asrEventManager setParameter:nil forKey:BDS_ASR_AUDIO_INPUT_STREAM];
	[self.asrEventManager sendCommand:BDS_ASR_CMD_START];
//	[self onInitializing];
}
- (void)onEnd
{
	self.stopButton.enabled = NO;
	self.cancelButton.enabled = NO;
	self.startSpeedButton.enabled = YES;
}
- (NSDictionary *)parseLogToDic:(NSString *)logString
{
	NSArray *tmp = NULL;
	NSMutableDictionary *logDic = [[NSMutableDictionary alloc] initWithCapacity:3];
	NSArray *items = [logString componentsSeparatedByString:@"&"];
	for (NSString *item in items) {
		tmp = [item componentsSeparatedByString:@"="];
		if (tmp.count == 2) {
			[logDic setObject:tmp.lastObject forKey:tmp.firstObject];
		}
	}
	return logDic;
}

- (void)onStartWorking
{
	self.stopButton.enabled = YES;
	self.cancelButton.enabled = YES;
}

#pragma mark - delegate
- (void)WakeupClientWorkStatus:(int)workStatus obj:(id)aObj
{
	switch (workStatus) {
			case EWakeupEngineWorkStatusStarted: {
				[self printLogTextView:@"WAKEUP CALLBACK: Started.\n"];
				break;
			}
			case EWakeupEngineWorkStatusStopped: {
				[self printLogTextView:@"WAKEUP CALLBACK: Stopped.\n"];
				break;
			}
			case EWakeupEngineWorkStatusLoaded: {
				[self printLogTextView:@"WAKEUP CALLBACK: Loaded.\n"];
				break;
			}
			case EWakeupEngineWorkStatusUnLoaded: {
				[self printLogTextView:@"WAKEUP CALLBACK: UnLoaded.\n"];
				break;
			}
			case EWakeupEngineWorkStatusTriggered: {
				[self printLogTextView:[NSString stringWithFormat:@"WAKEUP CALLBACK: Triggered - %@.\n", (NSString *)aObj]];
				if (self.continueToVR) {
					self.continueToVR = NO;
					[self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_NEED_CACHE_AUDIO];
					[self.asrEventManager setParameter:aObj forKey:BDS_ASR_OFFLINE_ENGINE_TRIGGERED_WAKEUP_WORD];
					[self voiceRecogButtonHelper];
				}
				break;
			}
			case EWakeupEngineWorkStatusError: {
				[self printLogTextView:[NSString stringWithFormat:@"WAKEUP CALLBACK: encount error - %@.\n", (NSError *)aObj]];
				break;
			}
			
		default:
			break;
	}
}

#pragma mark - BDRecognizerViewDelegate
- (void)VoiceRecognitionClientWorkStatus:(int)workStatus obj:(id)aObj
{
	switch (workStatus) {
			case EVoiceRecognitionClientWorkStatusNewRecordData: {
//				[self.fileHandler writeData:(NSData *)aObj];
				break;
			}
			
			case EVoiceRecognitionClientWorkStatusStartWorkIng: {
				NSDictionary *logDic = [self parseLogToDic:aObj];
				[self printLogTextView:[NSString stringWithFormat:@"CALLBACK: start vr, log: %@\n", logDic]];
				[self onStartWorking];
				break;
			}
			case EVoiceRecognitionClientWorkStatusStart: {
				[self printLogTextView:@"CALLBACK: detect voice start point.\n"];
				break;
			}
			case EVoiceRecognitionClientWorkStatusEnd: {
				[self printLogTextView:@"CALLBACK: detect voice end point.\n"];
				break;
			}
			case EVoiceRecognitionClientWorkStatusFlushData: {
				[self printLogTextView:[NSString stringWithFormat:@"CALLBACK: partial result - %@.\n\n", [self getDescriptionForDic:aObj]]];
				break;
			}
			case EVoiceRecognitionClientWorkStatusFinish: {
				[self printLogTextView:[NSString stringWithFormat:@"CALLBACK: final result - %@.\n\n", [self getDescriptionForDic:aObj]]];
				if (aObj) {
					self.resultTextView.text = [self getDescriptionForDic:aObj];
				}
				
					[self onEnd];
				
				break;
			}
			case EVoiceRecognitionClientWorkStatusMeterLevel: {
				break;
			}
			case EVoiceRecognitionClientWorkStatusCancel: {
				[self printLogTextView:@"CALLBACK: user press cancel.\n"];
				[self onEnd];
				break;
			}
			case EVoiceRecognitionClientWorkStatusError: {
				[self printLogTextView:[NSString stringWithFormat:@"CALLBACK: encount error - %@.\n", (NSError *)aObj]];
				[self onEnd];
				break;
			}
			case EVoiceRecognitionClientWorkStatusLoaded: {
				[self printLogTextView:@"CALLBACK: offline engine loaded.\n"];
				break;
			}
			case EVoiceRecognitionClientWorkStatusUnLoaded: {
				[self printLogTextView:@"CALLBACK: offline engine unLoaded.\n"];
				break;
			}
			case EVoiceRecognitionClientWorkStatusChunkThirdData: {
				[self printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk 3-party data length: %lu\n", (unsigned long)[(NSData *)aObj length]]];
				break;
			}
			case EVoiceRecognitionClientWorkStatusChunkNlu: {
				NSString *nlu = [[NSString alloc] initWithData:(NSData *)aObj encoding:NSUTF8StringEncoding];
				[self printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk NLU data: %@\n", nlu]];
				NSLog(@"%@", nlu);
				break;
			}
			case EVoiceRecognitionClientWorkStatusChunkEnd: {
				[self printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk end, sn: %@.\n", aObj]];
				
					[self onEnd];
				
				break;
			}
			case EVoiceRecognitionClientWorkStatusFeedback: {
				NSDictionary *logDic = [self parseLogToDic:aObj];
				[self printLogTextView:[NSString stringWithFormat:@"CALLBACK Feedback: %@\n", logDic]];
				break;
			}
			case EVoiceRecognitionClientWorkStatusRecorderEnd: {
				[self printLogTextView:@"CALLBACK: recorder closed.\n"];
				break;
			}
			case EVoiceRecognitionClientWorkStatusLongSpeechEnd: {
				[self printLogTextView:@"CALLBACK: Long Speech end.\n"];
				[self onEnd];
				break;
			}
		default:
			break;
	}
}

- (void)onRecordDataArrived:(NSData *)recordData sampleRate:(int)sampleRate
{
	
}

- (void)onEndWithViews:(BDRecognizerViewController *)aBDRecognizerViewController withResult:(id)aResult
{
	if (aResult) {
		self.resultTextView.text = [self getDescriptionForDic:aResult];
	}
	[self.asrEventManager setDelegate:self];
}
#pragma mark - 数据处理
- (NSString *)getDescriptionForDic:(NSDictionary *)dic {
	if (dic) {
		return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic
																			  options:NSJSONWritingPrettyPrinted
																				error:nil] encoding:NSUTF8StringEncoding];
	}
	return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
