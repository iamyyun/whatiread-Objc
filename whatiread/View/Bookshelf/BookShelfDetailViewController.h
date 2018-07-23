//
//  BookShelfDetailViewController.h
//  whatiread
//
//  Created by Yunju on 2018. 7. 5..
//  Copyright © 2018년 Yunju Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "whatiread+CoreDataModel.h"
#import "RateView.h"
#import "BookShelfViewController.h"

typedef void (^BookModifyCompleted)(NSString *bookTitle, NSString *bookAuthor, NSDate *bookDate, CGFloat fRate, NSMutableArray *bookQuotes, UIImage *bookImage);
typedef void (^BookDeleteCompleted)(NSIndexPath *indexPath);
typedef void (^BookmarkDeleteCompleted)(NSIndexPath *indexPath, NSInteger index, id<BookShelfViewControllerDelegate>delegate);

@interface BookShelfDetailViewController : CommonViewController

@property (nonatomic, copy) BookModifyCompleted bookModifyCompleted;
@property (nonatomic, copy) BookDeleteCompleted bookDeleteCompleted;
@property (nonatomic, copy) BookmarkDeleteCompleted bookmarkDeleteCompleted;
@property (nonatomic, weak) Book *book;
@property (nonatomic, strong) NSIndexPath *indexPath;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet RateView *rateView;
@property (weak, nonatomic) IBOutlet UILabel *bmCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *completeDateLabel;
@property (weak, nonatomic) IBOutlet UIButton *addBmBtn;
@property (weak, nonatomic) IBOutlet UIButton *editBsBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBsBtn;
@property (weak, nonatomic) IBOutlet UICollectionView *bookShelfCollectionView;

- (IBAction)addBookmarkBtnAction:(id)sender;
- (IBAction)EditBookShelfBtnAction:(id)sender;
- (IBAction)deleteBookShelfBtnAction:(id)sender;

- (void)setBookCompositionHandler:(Book *)book bookModifyCompleted:(BookModifyCompleted)bookModifyCompleted bookDeleteCompleted:(BookDeleteCompleted)bookDeleteCompleted bookmarkDeleteCompleted:(BookmarkDeleteCompleted)bookmarkDeleteCompleted;

@end
