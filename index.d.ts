declare module "@heytea/react-native-wechat" {
  export function registerApp(appId: string): Promise<boolean>;
  export function isWXAppInstalled(): Promise<boolean>;
  export function isWXAppSupportApi(): Promise<boolean>;
  export function getApiVersion(): Promise<string>;
  export function openWXApp(): Promise<boolean>;
  export interface AuthResponse {
    errCode?: number;
    errStr?: string;
    openId?: string;
    code?: string;
    url?: string;
    lang?: string;
    country?: string;
  }
  export function sendAuthRequest(
    scope: string | string[],
    state?: string
  ): Promise<AuthResponse>;
  export interface ShareMetadata {
    type:
    | "news"
    | "text"
    | "imageUrl"
    | "imageFile"
    | "imageResource"
    | "video"
    | "audio"
    | "file";
    thumbImage?: string;
    description?: string;
    webpageUrl?: string;
    imageUrl?: string;
    videoUrl?: string;
    musicUrl?: string;
    filePath?: string;
    fileExtension?: string;
  }
  export function shareToTimeline(
    message: ShareMetadata
  ): Promise<{ errCode?: number; errStr?: string }>;
  export function shareToSession(
    message: ShareMetadata
  ): Promise<{ errCode?: number; errStr?: string }>;

  export function shareToFavorite(
    message: ShareMetadata
  ): Promise<{ errCode?: number; errStr?: string }>;

  export interface ILaunchMiniProgramParam {
    userName: string;
    miniProgramType: number;
    path?: string
  }

  export function launchMiniProgram(param: ILaunchMiniProgramParam): Promise<{ errCode?: number; errStr?: string }>;

  export function openAuthPage(url: string): Promise<{ errCode?: number }>;

  export interface PaymentLoad {
    partnerId: string;
    prepayId: string;
    nonceStr: string;
    timeStamp: string;
    package: string;
    sign: string;
  }
  export function pay(
    payload: PaymentLoad
  ): Promise<{ errCode?: number; errStr?: string }>;


  export interface ShareMiniProgram {
    webpageUrl: string;
    miniprogramType: number;
    userName: string;
    path: string;
    title: string;
    description: string;
    imageUrl: string;
  }
  export function shareMiniProgram(data: ShareMiniProgram): Promise<{ errCode?: number; errStr?: string }>;


  export function jpPay(): Promise<{ errCode?: number; errStr?: string }>;
}



