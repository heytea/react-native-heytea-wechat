//
//  RCTWeChat.m
//  RCTWeChat
//
//  Created by Yorkie Liu on 10/16/15.
//  Copyright © 2015 WeFlex. All rights reserved.
//

#import "RCTWeChat.h"

#import <WXApiObject.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTBridge.h>
#import <React/RCTLog.h>
#import <React/RCTImageLoader.h>

// Define error messages
#define NOT_REGISTERED (@"registerApp required.")
#define INVOKE_FAILED (@"WeChat API invoke returns false.")


@implementation RCTWeChat

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURL:) name:@"RCTOpenURLNotification" object:nil];
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)handleOpenURL:(NSNotification *)aNotification
{
    NSString * aURLString =  [aNotification userInfo][@"url"];
    NSURL * aURL = [NSURL URLWithString:aURLString];

    if ([WXApi handleOpenURL:aURL delegate:self])
    {
        return YES;
    } else {
        return NO;
    }
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}


- (NSArray<NSString *> *)supportedEvents {
    
    return @[RCTWXEventName];
    
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

RCT_EXPORT_METHOD(registerApp:(NSString *)appid
                  :(RCTResponseSenderBlock)callback)
{
    self.appId = appid;
    [WXApi registerApp:appid universalLink:@"https://m.heytea-co.com/"];
    callback(@[[NSNull null]]);
}

RCT_EXPORT_METHOD(isWXAppInstalled:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], @([WXApi isWXAppInstalled])]);
}

RCT_EXPORT_METHOD(isWXAppSupportApi:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], @([WXApi isWXAppSupportApi])]);
}

RCT_EXPORT_METHOD(getWXAppInstallUrl:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], [WXApi getWXAppInstallUrl]]);
}

RCT_EXPORT_METHOD(getApiVersion:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], [WXApi getApiVersion]]);
}

RCT_EXPORT_METHOD(openWXApp:(RCTResponseSenderBlock)callback)
{
    callback(@[([WXApi openWXApp] ? [NSNull null] : INVOKE_FAILED)]);
}

RCT_EXPORT_METHOD(sendRequest:(NSString *)openid
                  :(RCTResponseSenderBlock)callback)
{
    BaseReq* req = [[BaseReq alloc] init];
    req.openID = openid;
    [WXApi sendReq:req completion:^(BOOL success) {
        callback(@[success ? [NSNull null] : INVOKE_FAILED]);
    }];
   
}

RCT_EXPORT_METHOD(sendAuthRequest:(NSString *)scope
                  :(NSString *)state
                  :(RCTResponseSenderBlock)callback)
{
    SendAuthReq* req = [[SendAuthReq alloc] init];
    req.scope = scope;
    req.state = state;
    [WXApi sendReq:req completion:^(BOOL success) {
        callback(@[success ? [NSNull null] : INVOKE_FAILED]);
    }];
   
}

RCT_EXPORT_METHOD(sendSuccessResponse:(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXSuccess;
    [WXApi sendResp:resp completion:^(BOOL success) {
        callback(@[success ? [NSNull null] : INVOKE_FAILED]);
    }];
   
}

RCT_EXPORT_METHOD(sendErrorCommonResponse:(NSString *)message
                  :(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXErrCodeCommon;
    resp.errStr = message;
    [WXApi sendResp:resp completion:^(BOOL success) {
        callback(@[success ? [NSNull null] : INVOKE_FAILED]);
    }];
  
}

RCT_EXPORT_METHOD(sendTicketReq:(NSString *)req)
{
    WXInvoiceAuthInsertReq *invoice = [[WXInvoiceAuthInsertReq alloc] init];
    invoice.urlString = req;
    [WXApi sendReq:invoice completion:^(BOOL success) {
            
    }];
}

RCT_EXPORT_METHOD(sendErrorUserCancelResponse:(NSString *)message
                  :(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXErrCodeUserCancel;
    resp.errStr = message;
    [WXApi sendResp:resp completion:^(BOOL success) {
        callback(@[success ? [NSNull null] : INVOKE_FAILED]);
    }];
    
}

RCT_EXPORT_METHOD(shareToTimeline:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToWeixinWithData:data scene:WXSceneTimeline callback:callback];
}

RCT_EXPORT_METHOD(shareToSession:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToWeixinWithData:data scene:WXSceneSession callback:callback];
}

RCT_EXPORT_METHOD(shareToMini:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    dispatch_queue_t que = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    WXMiniProgramObject *miniObj = [WXMiniProgramObject object];
    miniObj.webpageUrl = data[@"webpageUrl"];
    miniObj.userName = data[@"userName"];
    miniObj.path = data[@"path"];
    dispatch_group_enter(group);
    dispatch_async(que, ^{
        miniObj.hdImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString: data[@"thumbImage"]]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), que, ^{
            dispatch_group_leave(group);
        });
    });
   
    miniObj.withShareTicket = NO;
    miniObj.miniProgramType = 0;
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = data[@"title"];
    message.description = data[@"description"];
    message.thumbData = nil;
   
    message.mediaObject = miniObj;
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc]init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneSession;
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [WXApi sendReq:req completion:^(BOOL success) {
            callback(@[success? [NSNull null] : @"fail"]);
        }];
    });
}

RCT_EXPORT_METHOD(pay:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
                  
{
    PayReq* req             = [PayReq new];
    req.partnerId           = data[@"partnerId"];
    req.prepayId            = data[@"prepayId"];
    req.nonceStr            = data[@"nonceStr"];
    req.timeStamp           = [data[@"timeStamp"] unsignedIntValue];
    req.package             = data[@"package"];
    req.sign                = data[@"sign"];
    
    [WXApi sendReq:req completion:^(BOOL success) {
        callback(@[success? [NSNull null] : @"fail"]);
    }];
    
}

RCT_EXPORT_METHOD(openAuthPage:(NSString *)url
                  :(RCTResponseSenderBlock)callback
                  ){
    
    WXInvoiceAuthInsertReq *req = [[WXInvoiceAuthInsertReq alloc] init];
    req.urlString = url;
    [WXApi sendReq:req completion:^(BOOL success) {
        callback(@[success ? [NSNull null] : INVOKE_FAILED]);
    }];
    
}

//launchMiniProgram:(NSString*)userName:(NSUInteger)miniProgramType:(NSString*)path
RCT_EXPORT_METHOD(launchMiniProgram:(NSDictionary *)data:(RCTResponseSenderBlock)callback) {

    NSString *userName = data[@"userName"];
    NSUInteger miniProgramType = [data[@"miniProgramType"] unsignedIntValue];
    NSString *path = data[@"path"];
    [self launchMiniProgram:userName miniProgramType:miniProgramType path:path callBack:callback];
}

- (void)launchMiniProgram:(NSString *)userName
          miniProgramType:(NSUInteger)miniProgramType
                     path:(NSString*)path
                 callBack:(RCTResponseSenderBlock)callback{
    WXLaunchMiniProgramReq *launchMiniProgramReq = [WXLaunchMiniProgramReq object];
    launchMiniProgramReq.userName = userName;
    launchMiniProgramReq.miniProgramType = miniProgramType;
    if(path != nil){
        launchMiniProgramReq.path = path;
    }

    [WXApi sendReq:launchMiniProgramReq completion:^(BOOL success) {
         callback(@[success ? [NSNull null] : INVOKE_FAILED]);
    }];
   
}

- (void)shareToWeixinWithData:(NSDictionary *)aData
                   thumbImage:(UIImage *)aThumbImage
                        scene:(int)aScene
                     callBack:(RCTResponseSenderBlock)callback
{
    NSString *type = aData[RCTWXShareType];

    if ([type isEqualToString:RCTWXShareTypeText]) {
        NSString *text = aData[RCTWXShareDescription];
        [self shareToWeixinWithTextMessage:aScene Text:text callBack:callback];
    } else {
        NSString * title = aData[RCTWXShareTitle];
        NSString * description = aData[RCTWXShareDescription];
        NSString * mediaTagName = aData[@"mediaTagName"];
        NSString * messageAction = aData[@"messageAction"];
        NSString * messageExt = aData[@"messageExt"];

        if (type.length <= 0 || [type isEqualToString:RCTWXShareTypeNews]) {
            NSString * webpageUrl = aData[RCTWXShareWebpageUrl];
            if (webpageUrl.length <= 0) {
                callback(@[@"webpageUrl required"]);
                return;
            }

            WXWebpageObject* webpageObject = [WXWebpageObject object];
            webpageObject.webpageUrl = webpageUrl;

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:webpageObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else if ([type isEqualToString:RCTWXShareTypeAudio]) {
            WXMusicObject *musicObject = [WXMusicObject new];
            musicObject.musicUrl = aData[@"musicUrl"];
            musicObject.musicLowBandUrl = aData[@"musicLowBandUrl"];
            musicObject.musicDataUrl = aData[@"musicDataUrl"];
            musicObject.musicLowBandDataUrl = aData[@"musicLowBandDataUrl"];

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:musicObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else if ([type isEqualToString:RCTWXShareTypeVideo]) {
            WXVideoObject *videoObject = [WXVideoObject new];
            videoObject.videoUrl = aData[@"videoUrl"];
            videoObject.videoLowBandUrl = aData[@"videoLowBandUrl"];

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:videoObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else if ([type isEqualToString:RCTWXShareTypeImageUrl] ||
                   [type isEqualToString:RCTWXShareTypeImageFile] ||
                   [type isEqualToString:RCTWXShareTypeImageResource]) {
            NSURL *url = [NSURL URLWithString:aData[RCTWXShareImageUrl]];
            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:url];
            [self.bridge.imageLoader loadImageWithURLRequest:imageRequest callback:^(NSError *error, UIImage *image) {
                if (image == nil){
                    callback(@[@"fail to load image resource"]);
                } else {
                    WXImageObject *imageObject = [WXImageObject object];
                    imageObject.imageData = UIImagePNGRepresentation(image);
                    
                    [self shareToWeixinWithMediaMessage:aScene
                                                  Title:title
                                            Description:description
                                                 Object:imageObject
                                             MessageExt:messageExt
                                          MessageAction:messageAction
                                             ThumbImage:aThumbImage
                                               MediaTag:mediaTagName
                                               callBack:callback];
                    
                }
            }];
        } else if ([type isEqualToString:RCTWXShareTypeFile]) {
            NSString * filePath = aData[@"filePath"];
            NSString * fileExtension = aData[@"fileExtension"];

            WXFileObject *fileObject = [WXFileObject object];
            fileObject.fileData = [NSData dataWithContentsOfFile:filePath];
            fileObject.fileExtension = fileExtension;

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:fileObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else {
            callback(@[@"message type unsupported"]);
        }
    }
}


- (void)shareToWeixinWithData:(NSDictionary *)aData scene:(int)aScene callback:(RCTResponseSenderBlock)aCallBack
{
    NSString *imageUrl = aData[RCTWXShareTypeThumbImageUrl];
    if (imageUrl.length && _bridge.imageLoader) {
        NSURL *url = [NSURL URLWithString:imageUrl];
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:url];
        [_bridge.imageLoader loadImageWithURLRequest:imageRequest size:CGSizeMake(100, 100) scale:1 clipped:FALSE resizeMode:RCTResizeModeStretch progressBlock:nil partialLoadBlock:nil
            completionBlock:^(NSError *error, UIImage *image) {
            [self shareToWeixinWithData:aData thumbImage:image scene:aScene callBack:aCallBack];
        }];
    } else {
        [self shareToWeixinWithData:aData thumbImage:nil scene:aScene callBack:aCallBack];
    }

}

- (void)shareToWeixinWithTextMessage:(int)aScene
                                Text:(NSString *)text
                                callBack:(RCTResponseSenderBlock)callback
{
    SendMessageToWXReq* req = [SendMessageToWXReq new];
    req.bText = YES;
    req.scene = aScene;
    req.text = text;

    [WXApi sendReq:req completion:^(BOOL success) {
        callback(@[success ? [NSNull null] : INVOKE_FAILED]);
    }];
 
}

- (void)shareToWeixinWithMediaMessage:(int)aScene
                                Title:(NSString *)title
                          Description:(NSString *)description
                               Object:(id)mediaObject
                           MessageExt:(NSString *)messageExt
                        MessageAction:(NSString *)action
                           ThumbImage:(UIImage *)thumbImage
                             MediaTag:(NSString *)tagName
                             callBack:(RCTResponseSenderBlock)callback
{
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = description;
    message.mediaObject = mediaObject;
    message.messageExt = messageExt;
    message.messageAction = action;
    message.mediaTagName = tagName;
    [message setThumbImage:thumbImage];

    SendMessageToWXReq* req = [SendMessageToWXReq new];
    req.bText = NO;
    req.scene = aScene;
    req.message = message;

    [WXApi sendReq:req completion:^(BOOL success) {
        callback(@[success ? [NSNull null] : INVOKE_FAILED]);
    }];
   
}

#pragma mark - wx callback

-(void) onReq:(BaseReq*)req
{
    // TODO(Yorkie)
}

-(void) onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
        SendMessageToWXResp *r = (SendMessageToWXResp *)resp;
    
        NSMutableDictionary *body = @{@"errCode":@(r.errCode)}.mutableCopy;
        body[@"errStr"] = r.errStr == nil?@"":r.errStr;
        body[@"lang"] = r.lang;
        body[@"country"] =r.country;
        body[@"type"] = @"SendMessageToWX.Resp";
        [self sendEventWithName:RCTWXEventName body:body];
    } else if ([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *r = (SendAuthResp *)resp;
        NSMutableDictionary *body = @{@"errCode":@(r.errCode)}.mutableCopy;
        body[@"errStr"] = r.errStr == nil?@"":r.errStr;
        body[@"state"] = r.state;
        body[@"lang"] = r.lang;
        body[@"country"] =r.country;
        body[@"type"] = @"SendAuth.Resp";
    
        if (resp.errCode == WXSuccess)
        {
            [body addEntriesFromDictionary:@{@"appid":self.appId, @"code" :r.code}];
        }
        [self sendEventWithName:RCTWXEventName body:body];
        
    } else if ([resp isKindOfClass:[PayResp class]]) {
            PayResp *r = (PayResp *)resp;
            NSMutableDictionary *body = @{@"errCode":@(r.errCode)}.mutableCopy;
            body[@"errStr"] = r.errStr == nil?@"":r.errStr;
            body[@"resType"] = @(r.type);
            body[@"returnKey"] =r.returnKey;
            body[@"type"] = @"PayReq.Resp";
            [self sendEventWithName:RCTWXEventName body:body];
    }else if ([resp isKindOfClass:[WXLaunchMiniProgramResp class]]) {
        NSString *payload = [(WXLaunchMiniProgramResp*)resp extMsg];
        if (payload && payload.length > 0) {
            NSDictionary *body = @{
                                   @"status":payload,
                                   @"errStr":resp.errStr == nil?@"":resp.errStr,
                                   @"errCode":@(resp.errCode),
                                   @"type":@"LaunchMiniProgram.Resp"
                                   };
            [self sendEventWithName:RCTWXEventName body:body];
        }
    }else if ([resp isKindOfClass:[WXInvoiceAuthInsertResp class]]) {
        WXInvoiceAuthInsertResp *wxResp = (WXInvoiceAuthInsertResp *) resp;
        NSDictionary *body  = @{
            @"errCode":@(wxResp.errCode),
            @"type":@"WXInvoiceAuthInsertResp.Resp"
        };
       [self sendEventWithName:RCTWXEventName body:body];
       
    }
}

@end


