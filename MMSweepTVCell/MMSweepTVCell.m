//
//  MMSweepTVCell.m
//  navi_demo
//
//  Created by yangjie on 2019/6/3.
//  Copyright © 2019 Mumu. All rights reserved.
//

#import "MMSweepTVCell.h"

// iPhone 屏幕宽度
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
// iPhone 屏幕高度
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
//蒙层view
@interface MMSwipeTableInputOverlay: UIView
@property (nonatomic, weak) MMSweepTVCell * currentCell;
@end

@interface MMSweepTVCell ()
/**
 最底部view。所有action都加到这里。
 */
@property (nonatomic, strong) UIView *sweepContainerView;

@property (nonatomic, strong) UIPanGestureRecognizer *gesture;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, strong) NSArray <MMSweepAction *> *actionArray;

@property (nonatomic, assign) CGRect currentContentFrame;
@property (nonatomic, strong) NSMutableArray *actionFrameArray;
@property (nonatomic, strong) NSMutableArray *actionFinalFrameArray;

@property (nonatomic, strong) MMSwipeTableInputOverlay *mMaskView;

@property (nonatomic, assign) MMSweepTVCellState cellStates;
@end

@implementation MMSweepTVCell {
    CGFloat _contentHeight;
    CGFloat _actionViewWidth;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        //        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self mm_initSubView];
        self.cellStates = MMSweepTVCellStateDefault;
        _scrollDirection = -1;
        _actionFrameArray = [NSMutableArray array];
        _actionFinalFrameArray = [NSMutableArray array];
        _highlightColor = [UIColor lightGrayColor];
        _normalColor = [UIColor whiteColor];
        //        [self addConstantsForSubviews];
    }
    return self;
}
- (void)mm_initSubView {
    _sweepContainerView = [[UIView alloc] init];
    _subContainerView = [[UIView alloc] init];
    //    _subContainerView.backgroundColor = [UIColor whiteColor];
    UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pandGesture:)];
    self.gesture = gesture;
    [_subContainerView addGestureRecognizer:self.gesture];
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [_subContainerView addGestureRecognizer:_tapGesture];
    
    [self.contentView addSubview:self.sweepContainerView];
    [self.sweepContainerView addSubview:self.subContainerView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    //    NSLog(@"value= %@",[NSValue valueWithCGRect:self.contentView.frame]);
    
    if (self.sweepDelegate && [self.sweepDelegate respondsToSelector:@selector(sweepCellContentViewEdge:)]) {
        UIEdgeInsets edge = [self.sweepDelegate sweepCellContentViewEdge:self];
        CGRect frame = self.contentView.bounds;
        self.sweepContainerView.frame = CGRectMake(frame.origin.x + edge.left, frame.origin.y - edge.top, frame.size.width - edge.left - edge.right, frame.size.height - edge.top - edge.bottom);
        //        self.subContainerView.frame = self.sweepContainerView.bounds;
    } else {
        self.sweepContainerView.frame = self.contentView.bounds;
    }
    self.subContainerView.frame = self.sweepContainerView.bounds;
}
- (void)pandGesture:(UIPanGestureRecognizer *)sender {
    CGPoint offset = [sender translationInView:self.subContainerView];
    //    NSLog(@"识别到 point=%@",[NSValue valueWithCGPoint:offset]);
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.cellStates =  _cellStates == MMSweepTVCellStateEdited ? MMSweepTVCellStateEditedScrolling :MMSweepTVCellStateScrolling;
        NSLog(@"UIGestureRecognizerStateBegan=%f",offset.x);
        _currentContentFrame = self.subContainerView.frame;
        if (offset.x <= 0) {
            NSLog(@"💜💜💜💜💜💜💜💜=%f",offset.x);
            _currentContentFrame = self.subContainerView.frame;
            if (self.actionArray.count) {
                return;
            }
            [self sweepLeftAddAction];
        }
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        if (offset.x < 0) { //可能按钮添加失败的情况
            if (!self.actionArray.count) {
                [self sweepLeftAddAction];
            }
        }
        if (!self.actionArray.count) {
            return;
        }
        [self setFrameWithOffset:offset.x];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        
        //        NSLog(@"UIGestureRecognizerStateEnded");
        if (fabs(self.subContainerView.frame.origin.x) < _actionViewWidth *0.5) { //取消编辑
            self.cellStates = MMSweepTVCellStateEdited;
            [self handleTapGesture:nil];
        } else { //最大展示距离
            
            //            [self.actionFinalFrameArray removeAllObjects];
            [UIView animateWithDuration:0.25 animations:^{
                [self recoverActionStatus:2];
            } completion:^(BOOL finished) {
                self.cellStates = MMSweepTVCellStateEdited;
                [self handleMaskViewStatus:YES];
            }];
        }
    } else if (sender.state == UIGestureRecognizerStateCancelled) {
        NSLog(@"UIGestureRecognizerStateCancelled");
        
    } else if (sender.state == UIGestureRecognizerStateFailed) {
        NSLog(@"UIGestureRecognizerStateFailed");
    }
}

/**
 处理滑动偏移
 
 @param offsetX offsetX
 */
- (void)setFrameWithOffset:(CGFloat)offsetX {
    if (_scrollDirection < 0) {
        if ([self.sweepDelegate respondsToSelector:@selector(sweepCellScrollDirection:indexPath:)]) {
            _scrollDirection = [self.sweepDelegate sweepCellScrollDirection:self indexPath:self.mIndexPath];
        } else {
            _scrollDirection = MMSweepTVCellScrollDefault;
        }
    }
    if (_scrollDirection == MMSweepTVCellScrollDefault) {
        self.gesture.enabled = false;
        return;
    }
    if (_scrollDirection == MMSweepTVCellScrollHorizontalLeft) {
        CGRect frame = _currentContentFrame;
        CGFloat frameX = frame.origin.x;
        CGFloat ratio = 1.0/self.actionArray.count; //除以按钮总数量
        //    NSLog(@"frame44=%f,offsetx=%f",frameX,offsetX);
        if (self.cellStates == MMSweepTVCellStateScrolling) {
            if (offsetX + frameX < -_actionViewWidth) { //左滑超出按钮最大宽度
                CGFloat minOffset = (offsetX + _actionViewWidth) *0.2;
                frameX += minOffset - _actionViewWidth;
                [self setActionFinalFrameWithOffset:minOffset];
            } else {
                frameX += offsetX;
                if (self.actionArray.count) {
                    for (int i = 0; i< self.actionArray.count; ++i) {
                        MMSweepAction *action = self.actionArray[i];
                        //                    NSLog(@"ratio=%f",ratio);
                        CGRect aFrame = [self.actionFrameArray[i] CGRectValue];
                        CGRect fFrame = [self.actionFinalFrameArray[i] CGRectValue];
                        aFrame.origin.x += offsetX *(i) * ratio;
                        aFrame.origin.x =  MAX(fFrame.origin.x, aFrame.origin.x);
                        //                    NSLog(@"frame22=%f",aFrame.origin.x);
                        action.frame = aFrame;
                    }
                }
            }
        } else if (self.cellStates == MMSweepTVCellStateEditedScrolling) {
            if (offsetX + frameX < -_actionViewWidth) { //左滑超出按钮最大宽度
                CGFloat minOffset = offsetX *0.2;
                frameX += minOffset;
                //            NSLog(@"frame33=%f",frame.origin.x);
                [self setActionFinalFrameWithOffset:minOffset];
            } else {
                frameX += offsetX;
                if (self.actionArray.count > 1) {
                    for (int i = 0; i< self.actionArray.count; ++i) {
                        MMSweepAction *action = self.actionArray[i];
                        CGRect aFrame = [self.actionFinalFrameArray[i] CGRectValue];
                        aFrame.origin.x += offsetX *(i) * ratio;
                        //                    NSLog(@"frame99=%f",aFrame.origin.x);
                        action.frame = aFrame;
                    }
                }
            }
        }
        //右滑状态。
        if (frameX > 0) {
            self.cellStates = MMSweepTVCellStateScrolling;
            [self recoverActionStatus:1];
            //这里还需判断 action的frame是否 > 原始 frame。
            return;
        }
        frame.origin.x = frameX;
        self.subContainerView.frame = frame;
    }
}
- (void)setActionFinalFrameWithOffset:(CGFloat)minOffset {
    CGFloat ratio = 1.0/self.actionArray.count; //除以按钮总数量
    //    if (self.actionArray.count > 1) {
    for (int i = 0; i< self.actionArray.count; ++i) {
        MMSweepAction *action = self.actionArray[i];
        CGRect aFrame = [self.actionFinalFrameArray[i] CGRectValue];
        aFrame.origin.x += minOffset *(i+1) * ratio;
        aFrame.size.width += fabs(minOffset) * ratio;
        //            NSLog(@"frame11=%f,w=%f",aFrame.origin.x,aFrame.size.width);
        action.frame = aFrame;
    }
    //    }
}

/**
 改变action的状态  原始或者最终状态
 */
- (void)recoverActionStatus:(NSInteger)status {
    if (status == 1) { //原始状态
        self.subContainerView.frame = self.sweepContainerView.bounds;
    } else if (status == 2) { //最终状态
        CGRect maxFrame = self.subContainerView.frame;
        maxFrame.origin.x = -_actionViewWidth;
        self.subContainerView.frame = maxFrame;
    }
    NSArray *frameArr = status == 1? self.actionFrameArray : self.actionFinalFrameArray;
    for (int i = 0; i< self.actionArray.count; ++i) {
        MMSweepAction *action = self.actionArray[i];
        CGRect aFrame = [frameArr[i] CGRectValue];
        action.frame = aFrame;
    }
}
- (void)handleMaskViewStatus:(BOOL)show {
    if (show) {
        if (_mMaskView) {
            [_mMaskView removeFromSuperview];
        }
        UITableView * table = [self parentTable];
        _mMaskView = [[MMSwipeTableInputOverlay alloc] initWithFrame:table.bounds];
        _mMaskView.currentCell = self;
        [table addSubview:_mMaskView];
    } else {
        if (_mMaskView) {
            [_mMaskView removeFromSuperview];
        }
        _mMaskView = nil;
    }
}
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (self.cellStates == MMSweepTVCellStateDefault) {
        UITableView *superView = [self parentTable];
        if ([superView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
            [superView.delegate tableView:superView didSelectRowAtIndexPath:self.mIndexPath];
        }
        return;
    }
    if (self.cellStates == MMSweepTVCellStateEditedScrolling) {
        return;
    }
    if (self.cellStates == MMSweepTVCellStateEdited) {
        self.cellStates = MMSweepTVCellStateEditedScrolling;
    }
    
    CGRect frame = self.subContainerView.frame;
    frame.origin.x = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.subContainerView.frame = frame;
        for (MMSweepAction *action in self.actionArray) {
            action.frame = [self.actionFrameArray[0] CGRectValue];
        }
    } completion:^(BOOL finished) {
        [self sweepRemoveAllAction];
        [self handleMaskViewStatus:NO];
        self.cellStates = MMSweepTVCellStateDefault;
    }];
}

//action点击
- (void)handleActionClick:(MMSweepAction *)sender {
    if (sender.handleBlock) {
        sender.handleBlock(sender);
    }
}
- (void)sweepRemoveAllAction {
    if (self.actionArray.count) {
        for (MMSweepAction *action in self.actionArray) {
            [action removeFromSuperview];
        }
    }
    self.actionArray = nil;
}
- (void)sweepLeftAddAction {
    if (self.sweepDelegate && [self.sweepDelegate respondsToSelector:@selector(sweepCell:sweepActionsIndexPath:)]) {
        NSArray * actions = [self.sweepDelegate sweepCell:self sweepActionsIndexPath:self.mIndexPath];
        if (actions.count) {
            CGFloat height = self.sweepContainerView.bounds.size.height;
            int i = 0;
            _actionViewWidth = 0;
            if (self.actionFrameArray.count) {
                [self.actionFrameArray removeAllObjects];
            }
            for (MMSweepAction *action in actions) {
                CGFloat x = self.sweepContainerView.bounds.size.width;
                if (action.currentTitle.length) {
                    CGSize fitSize = [action sizeThatFits:CGSizeZero];
                    x -= fitSize.width + 50;
                    action.frame = CGRectMake(x - 30, 0, fitSize.width + 50 + 30, height);
                } else {
                    x -= 106;
                    action.frame = CGRectMake(x, 0, 106, height);
                }
                [action addTarget:self action:@selector(handleActionClick:) forControlEvents:UIControlEventTouchUpInside];
                action.contentEdgeInsets = UIEdgeInsetsMake(0, 30, 0, 0);
                [self.sweepContainerView addSubview:action];
                [self.sweepContainerView insertSubview:action atIndex:i++];
                [self.actionFrameArray addObject:[NSValue valueWithCGRect:action.frame]];
                _actionViewWidth += action.frame.size.width - 30;
            }
            self.actionArray = actions;
            //计算最后frame
            [self.actionFinalFrameArray removeAllObjects];
            CGFloat width = self.sweepContainerView.bounds.size.width -30;
            for (int i = 0; i< actions.count; ++i) {
                CGRect aFrame = [self.actionFrameArray[i] CGRectValue];
                aFrame.origin.x = width + 30 - aFrame.size.width;
                //                NSLog(@"x==%f",aFrame.origin.x);
                [self.actionFinalFrameArray addObject:[NSValue valueWithCGRect:aFrame]];
                width = aFrame.origin.x;
            }
            
        }
    }
}
#pragma mark - 公开方法
- (void)startEditingState:(MMSweepTVCellState)state {
    if (self.cellStates == state && (state == MMSweepTVCellStateEdited || state == MMSweepTVCellStateDefault)) {
        return;
    }
    if (state == MMSweepTVCellStateEdited) {
        if (!self.actionArray.count) {
            [self sweepLeftAddAction];
        }
        [UIView animateWithDuration:0.25 animations:^{
            [self recoverActionStatus:2];
        } completion:^(BOOL finished) {
            self.cellStates = MMSweepTVCellStateEdited;
            [self handleMaskViewStatus:YES];
        }];
    } else {
        [self handleTapGesture:nil];
    }
    
}
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        self.subContainerView.backgroundColor = self.highlightColor;
    } else {
        self.subContainerView.backgroundColor = self.normalColor;
    }
}
- (void)setContentCornerRadius:(CGFloat)contentCornerRadius {
    if (contentCornerRadius < 0) {
        return;
    }
    _contentCornerRadius = contentCornerRadius;
    self.subContainerView.layer.cornerRadius = contentCornerRadius;
    self.sweepContainerView.layer.cornerRadius = contentCornerRadius;
    //    self.subContainerView.layer.masksToBounds = YES;
}
- (void)setShadowColor:(UIColor *)shadowColor shadowOffset:(CGSize)shadowOffset shadowOpacity:(float)shadowOpacity shadowRadius:(CGFloat)shadowRadius {
    self.sweepContainerView.layer.shadowColor = shadowColor.CGColor;
    self.sweepContainerView.layer.shadowOffset = shadowOffset;
    self.sweepContainerView.layer.shadowOpacity = shadowOpacity;
    self.sweepContainerView.layer.shadowRadius = shadowRadius;
}
- (NSIndexPath *)mIndexPath {
    if (!_mIndexPath) {
        _mIndexPath = [[self parentTable] indexPathForCell:self];
    }
    return _mIndexPath;
}
- (void)setCellStates:(MMSweepTVCellState)cellStates {
    _cellStates = cellStates;
    if ([self respondsToSelector:@selector(notifyCurrentStatus:)]) {
        [self notifyCurrentStatus:cellStates];
    }
}
/**
 找到对应的tableview
 */
-(UITableView *) parentTable
{
    UIView * view = self.superview;
    while(view != nil) {
        if([view isKindOfClass:[UITableView class]]) {
            return (UITableView*) view;
        }
        view = view.superview;
    }
    return nil;
}

@end


@implementation MMSweepAction

+ (instancetype)sweepActionWith:(NSString *)title titleFont:(UIFont *)font titleColor:(UIColor *)titleColor imageName:(NSString *)imageName backgroundColor:(UIColor *)backgroundColor callBack:(HandleClickBlock)callBack {
    MMSweepAction *action = [MMSweepAction buttonWithType:UIButtonTypeCustom];
    if (title.length) {
        [action setTitle:title forState:UIControlStateNormal];
    }
    if (font) {
        action.titleLabel.font = font;
    }
    if (titleColor) {
        [action setTitleColor:titleColor forState:UIControlStateNormal];
    }
    if (imageName.length) {
        [action setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    }
    if (backgroundColor) {
        action.backgroundColor = backgroundColor;
    }
    if (callBack) {
        action.handleBlock = callBack;
    }
    return action;
}

@end




@implementation MMSwipeTableInputOverlay

-(id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (event == nil) {
        return nil;
    }
    if (!_currentCell) {
        [self removeFromSuperview];
        return nil;
    }
    CGPoint p = [self convertPoint:point toView:_currentCell];
    if (_currentCell && (_currentCell.hidden || CGRectContainsPoint(_currentCell.bounds, p))) {
        return nil;
    }
    BOOL hide = YES;
    //    if (_currentCell && _currentCell.delegate && [_currentCell.delegate respondsToSelector:@selector(swipeTableCell:shouldHideSwipeOnTap:)]) {
    //        hide = [_currentCell.delegate swipeTableCell:_currentCell shouldHideSwipeOnTap:p];
    //    }
    if (hide) {
        [_currentCell handleTapGesture:nil];
    }
    //    return [super hitTest:point withEvent:event];
    return nil;
}

@end
