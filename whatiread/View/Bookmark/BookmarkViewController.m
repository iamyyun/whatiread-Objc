//
//  BookmarkViewController.m
//  whatiread
//
//  Created by Yunju on 2018. 6. 4..
//  Copyright © 2018년 Yunju Yang. All rights reserved.
//

#import "BookmarkViewController.h"
#import "BookmarkCollectionViewCell.h"
#import "BookMarkHeaderCollectionReusableView.h"
#import "BookmarkDetailViewController.h"
#import <GKActionSheetPicker/GKActionSheetPicker.h>

#define MILLI_SECONDS           1000.f

@interface BookmarkViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate> {
    CoreDataAccess *coreData;
    
    BOOL isSearchBarActive;
    GKActionSheetPicker *sortPickerView;
    NSArray *sortArr;
    
    UITapGestureRecognizer *bgTap;
}

@end

@implementation BookmarkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIImage *image = [UIImage imageNamed:@"icon_menu_bookmark"];
    [self setNaviBarType:BAR_MENU title:NSLocalizedString(@"Bookmark", @"") image:image];
    
    [self.collectionView setAllowsSelection:YES];
    [self.collectionView registerNib:[UINib nibWithNibName:@"BookmarkCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"BookmarkCollectionViewCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"BookMarkHeaderCollectionReusableView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"BookMarkHeaderCollectionReusableView"];
    
    coreData = [CoreDataAccess sharedInstance];
    self.fetchedResultsController = coreData.fetchedResultsController;
    self.fetchedResultsController.delegate = self;
    self.quoteFetchedResultsController = coreData.quoteFetchedResultsController;
    self.quoteFetchedResultsController.delegate = self;
    self.managedObjectContext = coreData.managedObjectContext;
    self.quoteManagedObjectContext = coreData.quoteManagedObjectContext;
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    NSInteger bookCount = [sectionInfo numberOfObjects];
    NSInteger bmCount = 0;
    if (bookCount > 0) {
        for (int i = 0; i < bookCount; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            Book *book = [self.fetchedResultsController objectAtIndexPath:indexPath];
            bmCount += book.quotes.count;
        }
        [self.collectionView setHidden:NO];
        [self.emptyView setHidden:YES];
    } else {
        [self.collectionView setHidden:YES];
        [self.emptyView setHidden:NO];
    }
    
    [self.bCountLabel setText:[NSString stringWithFormat:@"%ld", bookCount]];
    [self.bmCountLabel setText:[NSString stringWithFormat:@"%ld", bmCount]];
    
    // Sort PickerView
    sortArr = @[@"완독일", @"책 제목", @"평점"];
    sortPickerView = [GKActionSheetPicker stringPickerWithItems:sortArr selectCallback:^(id selected) {
        [self sortBookmark:selected];
    } cancelCallback:nil];
    sortPickerView.selectButtonTitle = @"완료";
    sortPickerView.cancelButtonTitle = @"취소";
    
    // Add Observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShowNote:) name:UIWindowDidResignKeyNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHideNote:) name:UIWindowDidBecomeKeyNotification object:self.view.window];
    bgTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(writeFinished)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.managedObjectContext = nil;
    self.quoteManagedObjectContext = nil;
    self.fetchedResultsController = nil;
    self.quoteFetchedResultsController = nil;
    
    [coreData coreDataInitialize];
    self.fetchedResultsController = coreData.fetchedResultsController;
    self.fetchedResultsController.delegate = self;
    self.quoteFetchedResultsController = coreData.quoteFetchedResultsController;
    self.quoteFetchedResultsController.delegate = self;
    self.managedObjectContext = coreData.managedObjectContext;
    self.quoteManagedObjectContext = coreData.quoteManagedObjectContext;
    
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// resize image with fixed width
- (UIImage *)resizeImageWithWidth:(UIImage *)image targetWidth:(CGFloat)targetWidth {
    CGFloat scaleFactor = targetWidth / image.size.width;
    CGFloat targetHeight = image.size.height * scaleFactor;
    CGSize targetSize = CGSizeMake(targetWidth, targetHeight);
    
    UIGraphicsBeginImageContext(targetSize);
    [image drawInRect:CGRectMake(0, 0, targetWidth, targetHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void) writeFinished {
    [self.view endEditing:YES];
    
    [self.view removeGestureRecognizer:bgTap];
}

#pragma mark - navigation action
- (void)rightBarBtnClick:(id)sender
{
    [self.dimBgView setHidden:NO];
    [self.searchBar setHidden:NO];
    [self.searchBar becomeFirstResponder];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [self.view addGestureRecognizer:bgTap];
}

#pragma mark - actions
// add bookmark btn action
- (IBAction)addBtnAction:(id)sender {
//    [self bookConfigure:nil indexPath:nil isModifyMode:NO];
}

// sort btn action
- (IBAction)sortBtnAction:(id)sender {
    [sortPickerView presentPickerOnView:self.view];
}

// Sort Bookmark CollectionView
- (void)sortBookmark:(NSString *)strSelect {
    [self.sortLabel setText:strSelect];
    
    NSString *sortKey = @"";
    BOOL isAscending = NO;
    if ([strSelect isEqualToString:@"완독일"]) {
        sortKey = @"completeDate";
    } else if ([strSelect isEqualToString:@"책 제목"]) {
        isAscending = YES;
        sortKey = @"title";
    } else if ([strSelect isEqualToString:@"평점"]) {
        sortKey = @"rate";
    }
    
    NSFetchRequest *request = [self.fetchedResultsController fetchRequest];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:isAscending];
    [request setSortDescriptors:@[sortDescriptor]];
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Handle error
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [self.collectionView reloadData];
}

#pragma mark - Bookmark Configure
// delete Bookmark
- (void)deleteBookmark:(Book *)book indexPath:(NSIndexPath *)indexPath {
    NSFetchRequest <Quote *> *fetchRequest = Quote.fetchRequest;
    
    [self.managedObjectContext performBlock:^{
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
        NSArray *quoteArr = [book.quotes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        Quote *quote = quoteArr[indexPath.item];
        
        NSError * error;
        
        NSArray * resultArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if([resultArray count]) {
            [book removeQuotesObject:quote];
            
            [self.managedObjectContext save:&error];
            
//            if (!error) {
//                [self popController:YES];
//            }
        }
    }];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    isSearchBarActive = NO;
    
    self.managedObjectContext = nil;
    self.fetchedResultsController = nil;
    
    [coreData coreDataInitialize];
    self.fetchedResultsController = coreData.fetchedResultsController;
    self.fetchedResultsController.delegate = self;
    self.managedObjectContext = coreData.managedObjectContext;

    [self.view endEditing:YES];
    [self.dimBgView setHidden:YES];
    [self.searchBar setHidden:YES];
    [self.searchBar setText:@""];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    [self.collectionView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    isSearchBarActive = YES;
    [self.view addGestureRecognizer:bgTap];

    self.fetchedResultsController = nil;
    
    [coreData coreDataInitialize];
    self.fetchedResultsController = coreData.fetchedResultsController;
    self.fetchedResultsController.delegate = self;
    
    NSFetchRequest *request = [self.fetchedResultsController fetchRequest];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quotes.strData contains[cd] %@", searchBar.text];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@ OR quotes.data contains [cd] %@", searchBar.text, searchBar.text];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@ OR quotes contains[cd] %@", searchBar.text, searchBar.text];
    [request setPredicate:predicate];
    [request setSortDescriptors:@[sortDescriptor]];

    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Handle error
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource
- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"BookmarkCollectionViewCell";
    BookmarkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil] lastObject];
    }
    
    NSIndexPath *fetchIndexPath = [NSIndexPath indexPathForItem:indexPath.section inSection:0];
    Book *book = [self.fetchedResultsController objectAtIndexPath:fetchIndexPath];
    
    if (book) {
        
        NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
        NSArray *quoteArr = [book.quotes sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
        
        if (isSearchBarActive) {
            NSMutableArray *modiArr = [NSMutableArray array];
            for (int i = 0; i < book.quotes.count; i++) {
                Quote *quote = quoteArr[i];
                if ([quote.strData containsString:self.searchBar.text]) {
                    [modiArr addObject:quote];
                }
            }
            quoteArr = [modiArr copy];
        }
        
        if (quoteArr && quoteArr.count > 0) {
            Quote *quote = quoteArr[indexPath.item];
            NSAttributedString *attrQuote = (NSAttributedString *)quote.data;
            
            if (attrQuote && attrQuote.length > 0) {
                __block CGFloat height = [attrQuote boundingRectWithSize:CGSizeMake(cell.quoteTextView.frame.size.width, 1000) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil].size.height+1;
                
                [attrQuote enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, attrQuote.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
                    if (![value isKindOfClass:[NSTextAttachment class]]) {
                        return;
                    }
                    NSTextAttachment *attachment = (NSTextAttachment*)value;
                    CGFloat origHeight = attachment.image.size.height;
                    
                    NSLog(@"YJ << cell width : %f", cell.quoteTextView.frame.size.width);
                    NSLog(@"YJ << cell height : %f", height);
                    NSLog(@"YJ << image width : %f", attachment.image.size.width);
                    NSLog(@"YJ << image height : %f", origHeight);
                    
//                    CGFloat reHeight = (attachment.image.size.width / cell.quoteTextView.frame.size.width) * origHeight;
                    CGFloat reHeight = (cell.quoteTextView.frame.size.width / attachment.image.size.width) * origHeight;
                    attachment.bounds = CGRectMake(0, 0, cell.quoteTextView.frame.size.width, reHeight);
                    NSLog(@"YJ << reHight : %f", reHeight);
                    
                    if (reHeight > origHeight) {
                        height += (reHeight - origHeight);
                    } else if (reHeight < origHeight) {
                        height -= (origHeight - reHeight);
                    }
                    NSLog(@"YJ << final height : %f", height);
                }];
                
                [cell.quoteTextView setAttributedText:attrQuote];
                cell.quoteTextViewHeightConst.constant = height;
                cell.quoteTextView.contentSize = CGSizeMake(cell.quoteTextView.frame.size.width, height);
                [cell.quoteTextView setContentInset:UIEdgeInsetsZero];
                cell.quoteTextView.textContainerInset = UIEdgeInsetsZero;
                cell.quoteTextView.textContainer.lineFragmentPadding = 0;
                
                [cell updateConstraints];
            }
        }
    }

    [cell.indexLabel setText:[NSString stringWithFormat:@"%ld", (indexPath.item+1)]];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    BookMarkHeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"BookMarkHeaderCollectionReusableView" forIndexPath:indexPath];
    
    NSIndexPath *fetchIndexPath = [NSIndexPath indexPathForItem:indexPath.section inSection:0];
    Book *book = [self.fetchedResultsController objectAtIndexPath:fetchIndexPath];
    
    [headerView.titleLabel setText:book.title];
    [headerView.bmCountLabel setText:[NSString stringWithFormat:@"%ld", book.quotes.count]];
    
    return headerView;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    if (isSearchBarActive) {
        if ([sectionInfo numberOfObjects] > 0) {
            [self.dimBgView setHidden:YES];
        } else {
            [self.dimBgView setHidden:NO];
        }
    }
    
    NSLog(@"YJ << sections : %d", [sectionInfo numberOfObjects]);
    return [sectionInfo numberOfObjects];
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    NSInteger count = 0;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:section inSection:0];
    Book *book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSLog(@"YJ << quotes count : %d", book.quotes.count);
    
    if (isSearchBarActive) {
        NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
        NSArray *quoteArr = [book.quotes sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
        for (int i = 0; i < book.quotes.count; i++) {
            Quote *quote = quoteArr[i];
            if ([quote.strData containsString:self.searchBar.text]) {
                count += 1;
            }
        }
    }
    else {
        count = book.quotes.count;
    }
    return count;
}

#pragma mark - UICollectionViewDelegate
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    NSLog(@"YJ << select collectionview cell section : %ld, item : %ld", indexPath.section, indexPath.item);
    
    isSearchBarActive = NO;
    
    NSIndexPath *fetchIndexPath = [NSIndexPath indexPathForItem:indexPath.section inSection:0];
    Book *book = [self.fetchedResultsController objectAtIndexPath:fetchIndexPath];

    BookmarkDetailViewController *detailVC = [[BookmarkDetailViewController alloc] init];
    detailVC.book = book;
    detailVC.indexPath = indexPath;
    [detailVC setBookmarkDetailCompositionHandler:book bookmarkDeleteCompleted:^(NSIndexPath *indexPath) {
        [self deleteBookmark:book indexPath:indexPath];
    }];
    [self pushController:detailVC animated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = self.collectionView.frame.size.width;
    __block CGFloat height = 100.f;
    NSIndexPath *fetchIndexPath = [NSIndexPath indexPathForItem:indexPath.section inSection:0];
    Book *book = [self.fetchedResultsController objectAtIndexPath:fetchIndexPath];
    
    NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
    NSArray *quoteArr = [book.quotes sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];

    if (quoteArr && quoteArr.count > 0) {
        Quote *quote = quoteArr[indexPath.item];
        NSAttributedString *attrQuote = (NSAttributedString *)quote.data;
        
        if (attrQuote && attrQuote.length > 0) {
            height = [attrQuote boundingRectWithSize:CGSizeMake(width-61, 1000) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil].size.height+1;
            
            [attrQuote enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, attrQuote.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
                if (![value isKindOfClass:[NSTextAttachment class]]) {
                    return;
                }
                
                NSTextAttachment *attachment = (NSTextAttachment*)value;
                CGFloat origHeight = attachment.image.size.height;
//                CGFloat reHeight = (attachment.image.size.width / (width-61)) * origHeight;
                CGFloat reHeight = ((width-61) / attachment.image.size.width) * origHeight;
                
                if (reHeight > origHeight) {
                    height += (reHeight - origHeight);
                } else if (reHeight < origHeight) {
                    height -= (origHeight - reHeight);
                }
                NSLog(@"YJ << size of final height : %f", height);
            }];
        }
        
    }
    
    return CGSizeMake(width, (height+20));
}

#pragma mark - Fetched results controller
- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    if (controller == self.fetchedResultsController) {
        NSLog(@"YJ << NSFetchedResultsController - controllerWillChangeContent - BookmarkViewController");
        
        self.updateBlock = [NSBlockOperation new];
        
    }
}

- (void) controller:(NSFetchedResultsController *)controller didChangeSection:(nonnull id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    __weak UICollectionView *collectionView = self.collectionView;
    
    if (controller == self.fetchedResultsController) {
        NSLog(@"YJ << NSFetchedResultsController - didChangeSection - BookmarkViewController");
        
        switch(type) {
            case NSFetchedResultsChangeInsert: {
                [self.updateBlock addExecutionBlock:^{
                    //                    [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                    [collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                }];
            }
                break;
            case NSFetchedResultsChangeDelete: {
                [self.updateBlock addExecutionBlock:^{
                    //                    [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                    [collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                }];
            }
                break;
            default:
                return;
        }
    }
}

- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(nonnull id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath {
    
     __weak UICollectionView *collectionView = self.collectionView;
    
    if (controller == self.fetchedResultsController) {
        NSLog(@"YJ << NSFetchedResultsController - didChangeObject - BookmarkViewController");
        
        [self.updateBlock addExecutionBlock:^{
            [collectionView reloadData];
        }];
        
//        switch(type) {
//            case NSFetchedResultsChangeInsert: {
//                [self.updateBlock addExecutionBlock:^{
//                    //                     [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
//                    [collectionView reloadItemsAtIndexPaths:@[newIndexPath]];
//                }];
//                break;
//            }
//            case NSFetchedResultsChangeDelete: {
//                [self.updateBlock addExecutionBlock:^{
//                    //                    [collectionView deleteItemsAtIndexPaths:@[indexPath]];
//                    [collectionView reloadData];
//                }];
//                break;
//            }
//            case NSFetchedResultsChangeUpdate: {
//                [self.updateBlock addExecutionBlock:^{
////                    [collectionView reloadItemsAtIndexPaths:@[newIndexPath]];
//                    [collectionView reloadData];
//                }];
//                break;
//            }
//            case NSFetchedResultsChangeMove: {
//                [self.updateBlock addExecutionBlock:^{
//                    //                    [collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
////                    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
//                    [collectionView reloadData];
//                }];
//                break;
//            }
//        }
    }
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    if (controller == self.fetchedResultsController) {
        NSLog(@"YJ << NSFetchedResultsController - controllerDidChangeContent - BookmarkViewController");
        
        id <NSFetchedResultsSectionInfo> sectionInfo = [controller sections][0];
        NSInteger bookCount = [sectionInfo numberOfObjects];
        NSInteger bmCount = 0;
        if (bookCount > 0) {
            for (int i = 0; i < bookCount; i++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                Book *book = [self.fetchedResultsController objectAtIndexPath:indexPath];
                bmCount = book.quotes.count;
            }
            [self.collectionView setHidden:NO];
            [self.emptyView setHidden:YES];
        } else {
            [self.collectionView setHidden:YES];
            [self.emptyView setHidden:NO];
        }
        
        [self.bCountLabel setText:[NSString stringWithFormat:@"%ld", bookCount]];
        [self.bmCountLabel setText:[NSString stringWithFormat:@"%ld", bmCount]];
        
        [self.collectionView reloadData];
        
        [self.collectionView performBatchUpdates:^{
            [[NSOperationQueue currentQueue] addOperation:self.updateBlock];
        } completion:^(BOOL finished) {
            [self.collectionView reloadData];
        }];
    }
}

#pragma mark - keyboard actions
- (void)handleKeyboardWillShowNote:(NSNotification *)notification
{
    
    NSLog(@"YJ << keyboard show");
    [self.view addGestureRecognizer:bgTap];
    
    NSDictionary* userInfo = [notification userInfo];
    
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
}

- (void)handleKeyboardWillHideNote:(NSNotification *)notification
{
    NSLog(@"YJ << keyboard hide");
    [self.view removeGestureRecognizer:bgTap];
    
    NSDictionary* userInfo = [notification userInfo];
    
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
}

@end
