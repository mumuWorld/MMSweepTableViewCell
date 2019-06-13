//
//  MMSweepTVCell.h
//  navi_demo
//
//  Created by yangjie on 2019/6/3.
//  Copyright © 2019 Mumu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger,MMSweepTVCellState){
    MMSweepTVCellStateDefault           = 0, //默认模式
    MMSweepTVCellStateEdited            = 1, //编辑模式
    MMSweepTVCellStateScrolling         = 2, //从默认 ->滚动模式
    MMSweepTVCellStateEditedScrolling   = 3, //从编辑 ->滚动模式
};
typedef NS_ENUM(NSInteger,MMSweepTVCellScrollDirection){
    MMSweepTVCellScrollDefault               = 0, //不可滑动
    MMSweepTVCellScrollHorizontalLeft        = 1, //左滑
    MMSweepTVCellScrollHorizontalRight       = 2, //右滑
    MMSweepTVCellScrollHorizontal            = 3, //双向
};
@class MMSweepAction,MMSweepTVCell;

@protocol MMSweepTVCellSwipeDelegate <NSObject>


/**
 返回滑动方向
 */
- (MMSweepTVCellScrollDirection)sweepCellScrollDirection:(MMSweepTVCell *)sweepCell indexPath:(NSIndexPath *)indexPath;
/**
 返回滑动按钮,右边第一个 index == 0.
 */
- (NSArray <MMSweepAction *>*)sweepCell:(MMSweepTVCell *)sweepCell sweepActionsIndexPath:(NSIndexPath *)indexPath;

/**
 内容视图边距
 */
- (UIEdgeInsets)sweepCellContentViewEdge:(MMSweepTVCell *)sweepCell;

@optional
//是否支持长划手势，目前不实现
- (BOOL)sweepCell:(MMSweepTVCell *)sweepCell canLongSweepIndexPath:(NSIndexPath *)indexPath;

@end


@interface MMSweepTVCell : UITableViewCell

@property (nonatomic, weak) id<MMSweepTVCellSwipeDelegate> sweepDelegate;

/**
 cell的indexPath
 */
@property (nonatomic, strong) NSIndexPath *mIndexPath;
/**
 高亮颜色 默认灰色
 */
@property (nonatomic, strong) UIColor *highlightColor;
/**
 默认白色  正常背景色
 */
@property (nonatomic, strong) UIColor *normalColor;

/**
 圆角
 */
@property (nonatomic, assign) CGFloat contentCornerRadius;
/**
 滑动方向 目前只支持左滑
 */
@property (nonatomic, assign) MMSweepTVCellScrollDirection scrollDirection;

/**
 内容视图  子视图需要添加到这里。
 */
@property (nonatomic, strong) UIView *subContainerView;

/**
 设置阴影
 */
- (void)setShadowColor:(UIColor *)shadowColor shadowOffset:(CGSize)shadowOffset shadowOpacity:(float)shadowOpacity shadowRadius:(CGFloat)shadowRadius;

/**
 子类实现。用以告知当前状态。
 */
- (void)notifyCurrentStatus:(MMSweepTVCellState)state;

/**
 进入Or退出 编辑模式
 */
- (void)startEditingState:(MMSweepTVCellState)state;
@end


typedef void(^HandleClickBlock)(MMSweepAction *action);

/**
 滑动action
 */
@interface MMSweepAction : UIButton

@property (nonatomic, copy) HandleClickBlock handleBlock;
+ (instancetype)sweepActionWith:(NSString * _Nullable)title titleFont:(UIFont * _Nullable)font titleColor:(UIColor * _Nullable)titleColor imageName:(NSString * _Nullable)imageName backgroundColor:(UIColor * _Nullable)backgroundColor callBack:(HandleClickBlock)callBack;
@end


NS_ASSUME_NONNULL_END
