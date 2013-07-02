Third-party integration for [quick-cocos2d-x](https://github.com/dualface/quick-cocos2d-x), etc: Flurry, TestFlight, Umeng, GameCenter, iOS IAP, Google Play ...

SAVE YOUR LIFE :-)

91sdk:

1. add [[SDKNdcom shareApplication] init:appid appKey:appKey delegate:self isDebug:true] in AppController.mm 
2. call SDKNdCom.init() before gamelogic
3. call [[SDKNdcom shareApplication] pause] in enterforeground
