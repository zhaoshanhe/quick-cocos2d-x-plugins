Third-party integration for [quick-cocos2d-x](https://github.com/dualface/quick-cocos2d-x), etc: Flurry, TestFlight, Umeng, GameCenter, iOS IAP, Google Play ...

SAVE YOUR LIFE :-)

91sdk:

1. AppController.mm中添加 [[SDKNdcom shareApplication] init:appid appKey:appKey delegate:self isDebug:true]
2. SDKNdCom.init()游戏开始前调用
3. [[SDKNdcom shareApplication] pause]游戏挂起时，在enterforeground中调用
