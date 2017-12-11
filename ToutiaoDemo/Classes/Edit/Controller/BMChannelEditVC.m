//
//  BMChannelEditVC.m
//  ToutiaoDemo
//
//  Created by ___liangdahong on 2017/12/11.
//  Copyright © 2017年 ___liangdahong. All rights reserved.
//

#import "BMChannelEditVC.h"
#import "BMChannelEditCell.h"
#import "BMChannelModel.h"
#import <BMDragCellCollectionView/BMDragCellCollectionView.h>
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface BMChannelEditVC () <BMDragCollectionViewDataSource, BMDragCellCollectionViewDelegate>

@property (weak, nonatomic) IBOutlet BMDragCellCollectionView *dragCellCollectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionViewFlowLayout; ///< collectionViewFlowLayout
@property (nonatomic, strong) UIBarButtonItem *editButtonItem; ///< editButtonItem
@property (nonatomic, assign, getter=isEdit) BOOL edit; ///< edit

@end

static NSString *kBMChannelEditCell = @"kBMChannelEditCell";

@implementation BMChannelEditVC

- (UICollectionViewFlowLayout *)collectionViewFlowLayout {
    if (!_collectionViewFlowLayout) {
        _collectionViewFlowLayout = ({
            UICollectionViewFlowLayout *collectionViewFlowLayout = [UICollectionViewFlowLayout new];
            collectionViewFlowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
            collectionViewFlowLayout.minimumLineSpacing = 1;
            collectionViewFlowLayout.minimumInteritemSpacing = 1;
            collectionViewFlowLayout.itemSize = CGSizeMake((CGRectGetWidth([UIScreen mainScreen].bounds)-4)/4.0, 55);
            collectionViewFlowLayout.headerReferenceSize = CGSizeMake(100, 40);
            collectionViewFlowLayout;
        });
    }
    return _collectionViewFlowLayout;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"频道编辑";
    
    self.dragCellCollectionView.dragCellAlpha = 0.9;
    self.dragCellCollectionView.collectionViewLayout = self.collectionViewFlowLayout;
    self.dragCellCollectionView.alwaysBounceVertical = YES;
    [self.dragCellCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass(BMChannelEditCell.class) bundle:nil] forCellWithReuseIdentifier:kBMChannelEditCell];
    
    __weak typeof(self) weakSelf = self;
    self.editButtonItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"编辑" style:UIBarButtonItemStylePlain handler:^(id sender) {
        __strong typeof(weakSelf) self = weakSelf;
        self.edit = !self.edit;
        if (self.isEdit) {
            self.dragCellCollectionView.canDrag = YES;
            self.editButtonItem.title = @"编辑";
        } else {
            self.editButtonItem.title = @"退出编辑";
            self.dragCellCollectionView.canDrag = NO;
        }
        [self.dragCellCollectionView reloadData];
    }];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    self.dragCellCollectionView.canDrag = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"完成" style:UIBarButtonItemStylePlain handler:^(id sender) {
        __strong typeof(weakSelf) self = weakSelf;
        !self.editCompleteBlock ? : self.editCompleteBlock(self.channelModelArray);
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.channelModelArray.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.channelModelArray[section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BMChannelEditCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kBMChannelEditCell forIndexPath:indexPath];
    BMChannelModel *model = self.channelModelArray[indexPath.section][indexPath.row];
    // 删除按钮点击
    cell.block = ^(UICollectionViewCell *cell) {
        [self collectionView:collectionView didSelectItemAtIndexPath:[collectionView indexPathForCell:cell]];
    };
    
    // 这里需集合业务修改 调整代码
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.removeButton.hidden = YES;
            cell.titleLabel.text = model.title;
        } else {
            cell.removeButton.hidden = !self.isEdit;
            cell.titleLabel.text = model.title;
        }
    } else {
        cell.removeButton.hidden = YES;
        if (self.isEdit) {
            cell.titleLabel.text = [NSString stringWithFormat:@"+ %@", model.title];
        } else {
            cell.titleLabel.text = model.title;
        }
    }
    // 这里需集合业务修改 调整代码
    
    return cell;
}

- (NSArray *)dataSourceWithDragCellCollectionView:(BMDragCellCollectionView *)dragCellCollectionView {
    return self.channelModelArray;
}

- (void)dragCellCollectionView:(BMDragCellCollectionView *)dragCellCollectionView newDataArrayAfterMove:(NSArray *)newDataArray {
    self.channelModelArray = [newDataArray mutableCopy];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.item == 0) {
        [SVProgressHUD showSuccessWithStatus:self.channelModelArray[indexPath.section][indexPath.row].title];
        // 如果点击的是推荐
        return ;
    }
    if (!self.isEdit) {
        // 非边状态下
        [SVProgressHUD showSuccessWithStatus:self.channelModelArray[indexPath.section][indexPath.row].title];
        return;
    }

    if (indexPath.section == 0) {
        // 删除操作
        BMChannelModel *model = self.channelModelArray[indexPath.section][indexPath.row];
        BMChannelEditCell *cell = (BMChannelEditCell *)[collectionView cellForItemAtIndexPath:indexPath];
        cell.removeButton.hidden = YES;
        cell.titleLabel.text = [NSString stringWithFormat:@"+ %@", model.title];
        NSMutableArray *secArray0 = self.channelModelArray[indexPath.section];
        [secArray0 removeObject:model];
        NSMutableArray *secArray1 = self.channelModelArray[1];
        [secArray1 addObject:model];
        [collectionView moveItemAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForItem:secArray1.count-1 inSection:1]];
    } else {
        // 添加操作
        BMChannelModel *model = self.channelModelArray[indexPath.section][indexPath.row];
        BMChannelEditCell *cell = (BMChannelEditCell *)[collectionView cellForItemAtIndexPath:indexPath];
        cell.removeButton.hidden = NO;
        cell.titleLabel.text = model.title;
        NSMutableArray *secArray1 = self.channelModelArray[1];
        [secArray1 removeObject:model];
        NSMutableArray *secArray0 = self.channelModelArray[0];
        [secArray0 addObject:model];
        [collectionView moveItemAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForItem:secArray0.count-1 inSection:0]];
    }
}


- (BOOL)dragCellCollectionViewShouldBeginExchange:(BMDragCellCollectionView *)dragCellCollectionView sourceIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (destinationIndexPath.row == 0 && destinationIndexPath.section == 0) {
        // 如果拖拽到推荐cell不允许交换
        return NO;
    }
    if (sourceIndexPath.section == destinationIndexPath.section) {
        // 如果是相同组才可以交换（第一组的cell之间）
        return YES;
    }
    return NO;
}

- (BOOL)dragCellCollectionViewShouldBeginMove:(BMDragCellCollectionView *)dragCellCollectionView indexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        // 如果是第二组  不允许拖拽
        return NO;
    }
    if (indexPath.section == 0 && indexPath.item == 0) {
        // 如果是推荐Cell 不允许拖拽
        return NO;
    }
    return YES;
}

- (BOOL)dragCellCollectionView:(BMDragCellCollectionView *)dragCellCollectionView endedDragAutomaticOperationAtPoint:(CGPoint)point section:(NSInteger)section indexPath:(NSIndexPath *)indexPath {
    if (section == 1) {
        // 如果拖到了第一组松开就移动 而且内部不自动处理
        [dragCellCollectionView dragMoveItemToIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
        return NO;
    }
    return YES;
}

@end
