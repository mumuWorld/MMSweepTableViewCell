//
//  ViewController.m
//  SweepDemo
//
//  Created by yangjie on 2019/6/13.
//  Copyright © 2019 Mumu. All rights reserved.
//

#import "ViewController.h"
#import "MMSweepTVCell.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,MMSweepTVCellSwipeDelegate>
@property (nonatomic, strong) UITableView *listView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.listView];
    // Do any additional setup after loading the view.
}
#pragma mark - YZSweepTVCellSwipeDelegate
- (MMSweepTVCellScrollDirection)sweepCellScrollDirection:(MMSweepTVCell *)sweepCell indexPath:(NSIndexPath *)indexPath {
    return MMSweepTVCellScrollHorizontalLeft;
}
- (UIEdgeInsets)sweepCellContentViewEdge:(MMSweepTVCell *)sweepCell {
    return UIEdgeInsetsMake(0, 0, 10, 0);
}
- (NSArray<MMSweepAction *> *)sweepCell:(MMSweepTVCell *)sweepCell sweepActionsIndexPath:(NSIndexPath *)indexPath {
    MMSweepAction *action = [MMSweepAction sweepActionWith:@"删除" titleFont:nil titleColor:nil imageName:@"" backgroundColor:[UIColor blueColor] callBack:^(MMSweepAction * _Nonnull action) {
        NSLog(@"action1");
        [sweepCell startEditingState:MMSweepTVCellStateDefault];

    }];
    action.layer.cornerRadius = 8;
    
    MMSweepAction *editAction = [MMSweepAction sweepActionWith:@"" titleFont:nil titleColor:nil imageName:@"navi_add" backgroundColor:[UIColor lightGrayColor] callBack:^(MMSweepAction * _Nonnull action) {
        NSLog(@"action2");
        [sweepCell startEditingState:MMSweepTVCellStateDefault];
    }];
    editAction.layer.cornerRadius = 8;
    
    MMSweepAction *editAction2 = [MMSweepAction sweepActionWith:@"测试" titleFont:nil titleColor:nil imageName:@"navi_add" backgroundColor:[UIColor redColor] callBack:^(MMSweepAction * _Nonnull action) {
        NSLog(@"action3");
    }];
    editAction2.layer.cornerRadius = 8;

    return @[action,editAction,editAction2];
}
#pragma mark - delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"didSelect");
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MMSweepTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MMSweepTVCell"
                                                          forIndexPath: indexPath];
    cell.contentCornerRadius = 8;
    cell.normalColor = [UIColor cyanColor];
    cell.mIndexPath = indexPath;
    cell.sweepDelegate = self;
    return cell;
}
- (UITableView *)listView {
    if (!_listView) {
        UITableView *listView = [[UITableView alloc] initWithFrame:self.view.bounds];
        [listView registerClass:NSClassFromString(@"MMSweepTVCell") forCellReuseIdentifier:@"MMSweepTVCell"];
        listView.dataSource = self;
        listView.delegate = self;
        listView.rowHeight = 79;
        _listView = listView;
    }
    return _listView;
}
@end
