//
//  MasterViewController.m
//  OpenSafe
//
//  Created by tom on 4/3/13.
//
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "PasswordManager.h"

@interface MasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    
    NSArray *identifiers = [[PasswordManager sharedInstance] retrieveAllIdentifiers];
    for (NSString *identifier in identifiers) {
        [_objects insertObject:identifier atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)insertNewObject:(id)sender
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"New password"
                                                     message:@"Choose password type"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Generated", @"Input", nil];
    [alert setAlertViewStyle:UIAlertViewStyleDefault];
    [alert setTag:1];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            // Auto-generate password
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Generate password" message:@"Description" delegate:  self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
            [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
            [[alert textFieldAtIndex:0] setPlaceholder:@"Description"];
            [alert setTag:2];
            [alert show];
        } else if (buttonIndex == 2) {
            // Password provided by user
            UIAlertView * alert2 = [[UIAlertView alloc] initWithTitle:@"Input password" message:@"Description" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
            [alert2 setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
            [[alert2 textFieldAtIndex:0] setSecureTextEntry:NO];
            [[alert2 textFieldAtIndex:1] setSecureTextEntry:YES];
            [[alert2 textFieldAtIndex:0] setPlaceholder:@"Description"];
            [[alert2 textFieldAtIndex:1] setPlaceholder:@"Password"];
            [alert2 setTag:3];
            [alert2 show];
        }
    } else if (alertView.tag == 2 || alertView.tag == 3) {
        if (buttonIndex == 1) {
            // Grab a handle to our password manager
            PasswordManager *pm = [PasswordManager sharedInstance];
            if (alertView.tag ==2) {
                // Auto-generate password
                [pm generateAndStorePassword:[[alertView textFieldAtIndex:0] text]];
            } else if (alertView.tag == 3) {
                // Store user provided password
                [pm storePassword:[[alertView textFieldAtIndex:1] text]
                    forIdentifier:[[alertView textFieldAtIndex:0] text]];
            }
            [_objects insertObject:[[alertView textFieldAtIndex:0] text] atIndex:0];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    id object = _objects[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if([[PasswordManager sharedInstance] deletePassword:_objects[indexPath.row]]) {
            [_objects removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *password = [[PasswordManager sharedInstance] retreivePassword:_objects[indexPath.row]];
        [[segue destinationViewController] setDetailItem:password];
    }
}

@end
