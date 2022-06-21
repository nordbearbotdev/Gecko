import UIKit
import GraphQLite

//-----------------------------------------------------------------------------------------------------------------------------------------------
class ChatsView: UIViewController {

	@IBOutlet private var searchBar: UISearchBar!
	@IBOutlet private var tableView: UITableView!

	private var observerId: String?
	private var chatObjects: [ChatObject] = []

	//-------------------------------------------------------------------------------------------------------------------------------------------
	override init(nibName: String?, bundle: Bundle?) {

		super.init(nibName: nibName, bundle: bundle)

		tabBarItem.image = UIImage(systemName: "text.bubble")
		tabBarItem.title = "Все чаты"

		NotificationCenter.addObserver(self, selector: #selector(actionCleanup), text: Notifications.UserLoggedOut)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	required init?(coder: NSCoder) {

		super.init(coder: coder)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		title = "Все чаты"

		navigationItem.backBarButtonItem = UIBarButtonItem(title: "Отменить", style: .plain, target: nil, action: nil)
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(actionCompose))

		tableView.register(UINib(nibName: "ChatsCell", bundle: nil), forCellReuseIdentifier: "ChatsCell")

		tableView.tableFooterView = UIView()
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	override func viewWillAppear(_ animated: Bool) {

		super.viewWillAppear(animated)

		if (GQLAuth0.userId() != "") {
			loadChats()
			createObserver()
		}
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidAppear(_ animated: Bool) {

		super.viewDidAppear(animated)

		if (GQLAuth0.userId() != "") {
			if (DBUsers.fullname() != "") {

			} else { Users.onboard(self) }
		} else { Users.login(self) }
	}

	// MARK: - БД
	//-------------------------------------------------------------------------------------------------------------------------------------------
	func loadChats() {

		chatObjects.removeAll()

		let userId = GQLAuth0.userId()
		let text = searchBar.text ?? ""

		let arguments: [String: Any] = [":userId": userId, ":true": true, ":false": false, ":zero": 0.0, ":text": "%%\(text)%%"]

		var condition = "objectId IN (SELECT chatId FROM DBMember WHERE userId = :userId AND isActive = :true) AND "
		condition += "isDeleted = :false AND isArchived = :false AND isGroupDeleted = :false AND lastMessageAt != :zero AND details LIKE :text"

		chatObjects = ChatObject.fetchAll(gqldb, condition, arguments, order: "lastMessageAt DESC")

		tableView.reloadData()

		refreshTabCounter()
	}

	// MARK: - Обсервер
	//-------------------------------------------------------------------------------------------------------------------------------------------
	func createObserver() {

		if (observerId != nil) { return }

		let types: [GQLObserverType] = [.insert, .update]

		observerId = ChatObject.createObserver(gqldb, types) { method, objectId in
			DispatchQueue.main.async {
				self.loadChats()
			}
		}
	}

	// MARK: - Рефреш
	//-------------------------------------------------------------------------------------------------------------------------------------------
	func refreshTabCounter() {

		var total = 0

		for chatObject in chatObjects {
			total += chatObject.unreadCount
		}

		let item = tabBarController?.tabBar.items?[0]
		item?.badgeValue = (total != 0) ? "\(total)" : nil

		UIApplication.shared.applicationIconBadgeNumber = total
	}

	// MARK: - Действия Пользователя
	//-------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionCompose() {

		let selectUserView = SelectUserView()
		selectUserView.delegate = self
		let navController = NavigationController(rootViewController: selectUserView)
		present(navController, animated: true)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func actionNewChat() {

		if (tabBarController?.tabBar.isHidden ?? true) { return }

		tabBarController?.selectedIndex = 0

		actionCompose()
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func actionRecentUser(userId: String) {

		if (tabBarController?.tabBar.isHidden ?? true) { return }

		tabBarController?.selectedIndex = 0

		let chatId = DBSingles.create(userId)
		actionChatPrivate(chatId, userId)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func actionChatPrivate(_ chatId: String, _ recipientId: String) {

		view.endEditing(true)

		let chatPrivateView = ChatPrivateView(chatId, recipientId)
		chatPrivateView.hidesBottomBarWhenPushed = true
		navigationController?.pushViewController(chatPrivateView, animated: true)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func actionChatGroup(_ chatId: String) {

		view.endEditing(true)

		let chatGroupView = ChatGroupView(chatId)
		chatGroupView.hidesBottomBarWhenPushed = true
		navigationController?.pushViewController(chatGroupView, animated: true)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func actionDelete(_ indexPath: IndexPath) {

		let chatObject = chatObjects[indexPath.row]

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { action in
			DBDetails.update(chatId: chatObject.objectId, isDeleted: true)
		})
		alert.addAction(UIAlertAction(title: "Отменить", style: .cancel))

		present(alert, animated: true)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func actionMore(_ indexPath: IndexPath) {

		let chatObject = chatObjects[indexPath.row]

		let isMuted = chatObject.mutedUntil > Date().timestamp()
		let titleMute = isMuted ? "Отменить Обезвучивание" : "Обезвучить"

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: titleMute, style: .default) { action in
			if (isMuted)	{ self.actionUnmute(indexPath)	}
			if (!isMuted)	{ self.actionMute(indexPath)	}
		})
		alert.addAction(UIAlertAction(title: "Архивировать", style: .default) { action in
			DBDetails.update(chatId: chatObject.objectId, isArchived: true)
		})
		alert.addAction(UIAlertAction(title: "Отменить", style: .cancel))

		present(alert, animated: true)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func actionMute(_ indexPath: IndexPath) {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alert.addAction(UIAlertAction(title: "10 Часов", style: .default) { action in
			self.actionMute(indexPath, until: 10)
		})
		alert.addAction(UIAlertAction(title: "7 Дней", style: .default) { action in
			self.actionMute(indexPath, until: 168)
		})
		alert.addAction(UIAlertAction(title: "1 Месяц", style: .default) { action in
			self.actionMute(indexPath, until: 720)
		})
		alert.addAction(UIAlertAction(title: "1 Год", style: .default) { action in
			self.actionMute(indexPath, until: 8760)
		})
		alert.addAction(UIAlertAction(title: "Отменить", style: .cancel))

		present(alert, animated: true)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func actionMute(_ indexPath: IndexPath, until hours: Int) {

		let seconds = TimeInterval(hours * 60 * 60)
		let dateUntil = Date().addingTimeInterval(seconds)
		let mutedUntil = dateUntil.timestamp()

		let chatObject = chatObjects[indexPath.row]
		DBDetails.update(chatId: chatObject.objectId, mutedUntil: mutedUntil)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func actionUnmute(_ indexPath: IndexPath) {

		let chatObject = chatObjects[indexPath.row]
		DBDetails.update(chatId: chatObject.objectId, mutedUntil: 0)
	}

	// MARK: - Чистилище)))
	//-------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionCleanup() {

		ChatObject.removeObserver(gqldb, observerId)
		observerId = nil

		chatObjects.removeAll()
		tableView.reloadData()

		refreshTabCounter()
	}
}

// MARK: - SelectUserDelegate
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension ChatsView: SelectUserDelegate {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func didSelectUser(dbuser: DBUser) {

		let chatId = DBSingles.create(dbuser.objectId)
		actionChatPrivate(chatId, dbuser.objectId)
	}
}

// MARK: - UIScrollViewDelegate
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension ChatsView: UIScrollViewDelegate {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

		view.endEditing(true)
	}
}

// MARK: - UITableViewDataSource
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension ChatsView: UITableViewDataSource {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in tableView: UITableView) -> Int {

		return 1
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		return chatObjects.count
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: "ChatsCell", for: indexPath) as! ChatsCell

		let chatObject = chatObjects[indexPath.row]
		cell.bindData(chatObject)
		cell.loadImage(chatObject)

		return cell
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

		return true
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

		let actionDelete = UIContextualAction(style: .destructive, title: "Удалить") { action, sourceView, completionHandler in
			self.actionDelete(indexPath)
			completionHandler(true)
		}

		let actionMore = UIContextualAction(style: .normal, title: "Больше") { action, sourceView, completionHandler in
			self.actionMore(indexPath)
			completionHandler(true)
		}

		actionDelete.image = UIImage(systemName: "trash")
		actionMore.image = UIImage(systemName: "ellipsis")

		return UISwipeActionsConfiguration(actions: [actionDelete, actionMore])
	}
}

// MARK: - UITableViewDelegate
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension ChatsView: UITableViewDelegate {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		tableView.deselectRow(at: indexPath, animated: true)

		let chatObject = chatObjects[indexPath.row]

		if (chatObject.isGroup) {
			actionChatGroup(chatObject.objectId)
		}
		if (chatObject.isPrivate) {
			actionChatPrivate(chatObject.objectId, chatObject.userId)
		}
	}
}

// MARK: - UISearchBarDelegate
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension ChatsView: UISearchBarDelegate {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

		loadChats()
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

		searchBar.setShowsCancelButton(true, animated: true)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {

		searchBar.setShowsCancelButton(false, animated: true)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {

		searchBar.text = ""
		searchBar.resignFirstResponder()
		loadChats()
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

		searchBar.resignFirstResponder()
	}
}
