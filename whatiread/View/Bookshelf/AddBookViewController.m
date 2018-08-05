//
//  AddBookViewController.m
//  whatiread
//
//  Created by Yunju on 2018. 7. 18..
//  Copyright © 2018년 Yunju Yang. All rights reserved.
//

#import "AddBookViewController.h"
#import "LSLDatePickerDialog.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface AddBookViewController () <UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate> {
    UITapGestureRecognizer *bgTap;
    
    NSDate *publishDate;
    NSDate *startDate;
    NSDate *compDate;
}

@end

@implementation AddBookViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setNaviBarType:BAR_ADD title:@"책 등록" image:nil];
    
    publishDate = [NSDate date];
    startDate = [NSDate date];
    compDate = [NSDate date];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy.MM.dd"];
    NSString *strDate = [format stringFromDate:compDate];
    self.pubDateTextField.text = strDate;
    self.startDateTextField.text = strDate;
    self.compDateTextField.text = strDate;
    
    [self.compDateTextField resignFirstResponder];
    [self.compDateTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    
    [self.rateView setStarFillColor:[UIColor colorWithHexString:@"F0C330"]];
    [self.rateView setStarNormalColor:[UIColor lightGrayColor]];
    [self.rateView setCanRate:YES];
    [self.rateView setStarSize:30.f];
    [self.rateView setStep:0.5f];
    [self.rateView setDelegate:self];
    
    if (self.isModifyMode) {
        if (self.book) {
            [self.titleLabel setUserInteractionEnabled:NO];
            [self.authorLabel setUserInteractionEnabled:NO];
            [self.publisherLabel setUserInteractionEnabled:NO];
            [self.pubDateTextField setUserInteractionEnabled:NO];
            
            [self.coverImgView setImage:[UIImage imageWithData:self.book.coverImg]];
            
            publishDate = self.book.publishDate;
            startDate = self.book.startDate;
            compDate = self.book.completeDate;
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"yyyy.MM.dd"];
            
            NSString *strTitle = self.book.title;
            CGFloat height = [strTitle boundingRectWithSize:CGSizeMake(self.titleLabel.frame.size.width, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:19.0f]} context:nil].size.height;
            self.titleLabelHeightConst.constant = height;
            [self.titleLabel setText:strTitle];
            [self.authorLabel setText:self.book.author];
            [self.publisherLabel setText:self.book.publisher];
            [self.pubDateTextField setText:[format stringFromDate:publishDate]];
            [self.startDateTextField setText:[format stringFromDate:startDate]];
            [self.compDateTextField setText:[format stringFromDate:compDate]];
            [self.rateView setRating:self.book.rate];
            
            // set NavigationBar
            [self setNaviBarType:BAR_ADD title:@"책 수정" image:nil];
            
            if ([self isCheckField]) {
                [self.navigationItem.rightBarButtonItem setEnabled:YES];
            } else {
                [self.navigationItem.rightBarButtonItem setEnabled:NO];
            }
        }
    } else {
        if (self.bookDic) {
            
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"yyyy.MM.dd"];
            NSString *strDate = [format stringFromDate:compDate];
            
            NSString *strPubDate = [self makeDateString:[self.bookDic objectForKey:@"pubdate"]];
            publishDate = [format dateFromString:strPubDate];
            
            NSString *strTitle = [self makeMetaToString:[self.bookDic objectForKey:@"title"]];
            CGFloat height = [strTitle boundingRectWithSize:CGSizeMake(self.titleLabel.frame.size.width, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:19.0f]} context:nil].size.height;
            self.titleLabelHeightConst.constant = height;
            [self.titleLabel setText:strTitle];
            [self.authorLabel setText:[self makeMetaToString:[self.bookDic objectForKey:@"author"]]];
            [self.publisherLabel setText:[self.bookDic objectForKey:@"publisher"]];
            [self.pubDateTextField setText:strPubDate];
            [self.startDateTextField setText:strDate];
            [self.compDateTextField setText:strDate];
            [self.coverImgView sd_setImageWithURL:[NSURL URLWithString:[self.bookDic objectForKey:@"image"]]];
            
            [self.titleLabel setUserInteractionEnabled:NO];
            [self.authorLabel setUserInteractionEnabled:NO];
            [self.publisherLabel setUserInteractionEnabled:NO];
            [self.pubDateTextField setUserInteractionEnabled:NO];
            
            // set NavigationBar
            [self setNaviBarType:BAR_ADD title:@"책 등록" image:nil];
            
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
        }
    }
    
    // Add Observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShowNote:) name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHideNote:) name:UIKeyboardWillHideNotification object:self.view.window];
    bgTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(writeFinished)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// check all necessary field
- (BOOL)isCheckField {
    NSString *strCompDate = self.compDateTextField.text;
    float strRate = self.rateView.rating;
    
    if (strCompDate.length > 0 && strRate > 0.0f) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)makeMetaToString:(NSString *)strMeta {
    NSString *strResult = @"";
    NSString *style = @"<meta charset=\"UTF-8\"><style> body { font-family: 'HelveticaNeue'; font-size: 15px; } b {font-family: 'MarkerFelt-Wide'; }</style>";
    NSString *meta = [NSString stringWithFormat:@"%@%@", style, strMeta];
    NSDictionary *options = @{ NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType };
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithData:[meta dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil error:nil];
    strResult = [NSString stringWithFormat:@"%@", [attrString string]];
    
    return strResult;
}

// set block
- (void)setAddBookCompositionHandler:(NSDictionary *)bDic addBookCreateCompleted:(AddBookCreateCompleted)bookshelfCreateCompleted addBookModifyCompleted:(AddBookModifyCompleted)bookshelfModifyCompleted
{
    self.bookDic = bDic;
    self.addBookCreateCompleted = bookshelfCreateCompleted;
    self.addBookModifyCompleted = bookshelfModifyCompleted;
}

- (void) writeFinished {
    [self.view endEditing:YES];
}

- (NSString *)makeDateString:(NSString *)strDate {
    NSMutableString *muString = [NSMutableString stringWithString:strDate];
    [muString insertString:@"." atIndex:4];
    [muString insertString:@"." atIndex:7];
    
    return [NSString stringWithString:muString];
}

-(void)addDoneToolBarToKeyboard:(UITextView *)textView
{
    CGFloat width = self.view.frame.size.width;
    UIToolbar* doneToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, width, 50)];
    doneToolbar.barStyle = UIBarStyleDefault;
    doneToolbar.items = [NSArray arrayWithObjects:
                         [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                         [[UIBarButtonItem alloc]initWithTitle:@"완료" style:UIBarButtonItemStyleDone target:self action:@selector(writeFinished)],
                         nil];
    [doneToolbar sizeToFit];
    textView.inputAccessoryView = doneToolbar;
}

#pragma mark - Navigation Bar Action
- (void)leftBarBtnClick:(id)sender {
    if (self.isModifyMode) {
        [self popController:YES];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Close", @"") message:@"작성중인 글이 있습니다." preferredStyle:UIAlertControllerStyleActionSheet];
        
        NSString *strFirst = @"계속 쓰기";
        NSString *strSecond = @"삭제하고 나가기";
        NSString *strThird = @"저장하고 나가기";
        UIAlertAction *firstAction = [UIAlertAction actionWithTitle:strFirst style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            
        }];
        UIAlertAction *secondAction = [UIAlertAction actionWithTitle:strSecond style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self popController:YES];
        }];
        UIAlertAction *thirdAction = [UIAlertAction actionWithTitle:strThird style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self rightBarBtnClick:nil];
        }];
        
        [alert addAction:firstAction];
        [alert addAction:secondAction];
        [alert addAction:thirdAction];
        [self presentController:alert animated:YES];
    }
}

- (void)rightBarBtnClick:(id)sender
{
    if (self.rateView.rating == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"평점을 매겨주세요." message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Confirm", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
        [alert addAction:okAction];
        [self presentController:alert animated:YES];
    }
    else {
        if (self.isModifyMode) {
            if (self.addBookModifyCompleted) {
                NSMutableDictionary *bookDic = [NSMutableDictionary dictionary];
                [bookDic setObject:self.titleLabel.text forKey:@"bTitle"];
                [bookDic setObject:self.authorLabel.text forKey:@"bAuthor"];
                [bookDic setObject:self.publisherLabel.text forKey:@"bPublisher"];
                [bookDic setObject:publishDate forKey:@"bPubDate"];
                [bookDic setObject:startDate forKey:@"bStartDate"];
                [bookDic setObject:compDate forKey:@"bCompleteDate"];
                [bookDic setObject:[NSNumber numberWithFloat:self.rateView.rating] forKey:@"bRate"];
                
                if (self.coverImgView.image) {
                    [bookDic setObject:self.coverImgView.image forKey:@"bCoverImg"];
                }
                
                self.addBookModifyCompleted(bookDic);
            }
        } else {
            // create bookmark data
            if (self.addBookCreateCompleted) {
                NSMutableDictionary *bookDic = [NSMutableDictionary dictionary];
                [bookDic setObject:self.titleLabel.text forKey:@"bTitle"];
                [bookDic setObject:self.authorLabel.text forKey:@"bAuthor"];
                [bookDic setObject:self.publisherLabel.text forKey:@"bPublisher"];
                [bookDic setObject:publishDate forKey:@"bPubDate"];
                [bookDic setObject:startDate forKey:@"bStartDate"];
                [bookDic setObject:compDate forKey:@"bCompleteDate"];
                
                [bookDic setObject:self.coverImgView.image forKey:@"bCoverImg"];
                
                [bookDic setObject:[NSNumber numberWithFloat:self.rateView.rating] forKey:@"bRate"];
                self.addBookCreateCompleted(bookDic);
            }
        }
        [self popController:YES];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSString *strTitle = @"";
    if (textField == self.startDateTextField) {
        strTitle = @"시작일";
    }
    else if (textField == self.compDateTextField) {
        strTitle = @"완독일";
    }
    
    LSLDatePickerDialog *dpDialog = [[LSLDatePickerDialog alloc] init];
    if (textField == self.startDateTextField) {
        [dpDialog showWithTitle:@"시작일" doneButtonTitle:@"확인" cancelButtonTitle:@"취소" defaultDate:[NSDate date] datePickerMode:UIDatePickerModeDate callback:^(NSDate *date) {
            if (date) {
                startDate = date;
                NSDateFormatter *format = [[NSDateFormatter alloc] init];
                [format setDateFormat:@"yyyy.MM.dd"];
                NSString *strDate = [format stringFromDate:date];
                textField.text = strDate;
            }
        }];
        return NO;
    }
    else if (textField == self.compDateTextField) {
        [dpDialog showWithTitle:@"완독일" doneButtonTitle:@"확인" cancelButtonTitle:@"취소" defaultDate:[NSDate date] datePickerMode:UIDatePickerModeDate callback:^(NSDate *date) {
            if (date) {
                compDate = date;
                NSDateFormatter *format = [[NSDateFormatter alloc] init];
                [format setDateFormat:@"yyyy.MM.dd"];
                NSString *strDate = [format stringFromDate:date];
                textField.text = strDate;
            }
        }];
        return NO;
    }
    
    return YES;
}

#pragma mark - RateView Delegate
- (void)rateView:(RateView *)rateView didUpdateRating:(float)rating {
    [self performSelector:@selector(setRate) withObject:nil afterDelay:0.1];
}

- (void)setRate {
    [self.rateLabel setText:[NSString stringWithFormat:@"%g", self.rateView.rating]];
    
    if ([self isCheckField]) {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
}

#pragma mark - keyboard actions
- (void)handleKeyboardWillShowNote:(NSNotification *)notification
{
    [self.view addGestureRecognizer:bgTap];
    
    NSDictionary* userInfo = [notification userInfo];
    
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
}

- (void)handleKeyboardWillHideNote:(NSNotification *)notification
{
    [self.view removeGestureRecognizer:bgTap];
    
    NSDictionary* userInfo = [notification userInfo];
    
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
}


@end