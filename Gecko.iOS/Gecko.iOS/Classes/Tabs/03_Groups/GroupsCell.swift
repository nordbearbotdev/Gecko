import UIKit

//-----------------------------------------------------------------------------------------------------------------------------------------------
class GroupsCell: UITableViewCell {

	@IBOutlet private var imageGroup: UIImageView!
	@IBOutlet private var labelInitials: UILabel!
	@IBOutlet private var labelName: UILabel!
	@IBOutlet private var labelMembers: UILabel!

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func bindData(_ dbgroup: DBGroup) {

		labelInitials.text = dbgroup.name.initial()
		labelName.text = dbgroup.name
		labelMembers.text = "\(dbgroup.members) members"
	}
}
