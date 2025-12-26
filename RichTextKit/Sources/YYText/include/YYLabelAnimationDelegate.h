//
//  YYLabelAnimationDelegate.h
//  YYTextDemo
//
//  Created by ByteDance on 2023/4/26.
//  Copyright © 2023 ibireme. All rights reserved.
//

@class YYLabel;
@protocol YYLabelAnimationDelegate <NSObject>

- (id<CAAction> _Nullable)label:(YYLabel * _Nonnull)label actionForLayer:(CALayer * _Nonnull)layer forKey:(NSString * _Nonnull)event;

@end
