import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/useAuth";

const FALLBACK_AVATAR =
  "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";

export default function Profile() {
  const navigate = useNavigate();
  const { logout, user } = useAuth();

  const displayName =
    user?.profile?.fullName ||
    `${user?.firstName || ""} ${user?.lastName || ""}`.trim() ||
    "Administrator";

  const handleLogout = async () => {
    await logout();
    navigate("/signin");
  };

  return (
    <div className="min-h-screen bg-slate-100 dark:bg-slate-900 flex justify-center p-6">
      <div className="flex flex-col justify-between w-full max-w-md">
        <div className="flex justify-center items-center flex-grow">
          <div className="w-full bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
            <div className="flex flex-col items-center text-center">
              <img
                src={user?.profile?.profileImage || FALLBACK_AVATAR}
                alt="Profile"
                className="w-28 h-28 rounded-full ring-4 ring-blue-500 object-cover"
              />

              <h2 className="mt-4 text-xl font-semibold text-slate-800 dark:text-white">
                {displayName}
              </h2>
              <button
                onClick={() => navigate("/profile/edit-profile")}
                className="text-blue-500 text-sm mt-1 hover:underline"
              >
                Edit profile
              </button>
            </div>

            <div className="mt-6 space-y-3">
              <div className="flex justify-between border-b pb-2 border-slate-200 dark:border-slate-700 gap-4">
                <span className="text-slate-600 dark:text-slate-400">Email</span>
                <span className="text-slate-800 dark:text-white text-right break-all">
                  {user?.email || "-"}
                </span>
              </div>

              <div className="flex justify-between border-b pb-2 border-slate-200 dark:border-slate-700">
                <span className="text-slate-600 dark:text-slate-400">Role</span>
                <span className="text-slate-800 dark:text-white">
                  {user?.role || "ADMIN"}
                </span>
              </div>

              <div className="flex justify-between border-b pb-2 border-slate-200 dark:border-slate-700">
                <span className="text-slate-600 dark:text-slate-400">Username</span>
                <span className="text-slate-800 dark:text-white">
                  {user?.profile?.username || "-"}
                </span>
              </div>

              <div className="flex justify-between border-b pb-2 border-slate-200 dark:border-slate-700">
                <span className="text-slate-600 dark:text-slate-400">Status</span>
                <span className="text-green-500 font-medium">Active</span>
              </div>

              <button
                onClick={() => navigate("/profile/add-admin")}
                className="mt-4 w-full bg-green-500 hover:bg-green-600 text-white py-2 rounded-lg transition"
              >
                Add New Admin
              </button>

              <button
                onClick={handleLogout}
                className="mt-2 w-full bg-red-500 hover:bg-red-600 text-white py-2 rounded-lg transition"
              >
                Logout
              </button>
            </div>
          </div>
        </div>

        <div className="w-full mt-6 p-4 bg-white dark:bg-slate-800 rounded-xl shadow">
          <div className="flex items-start space-x-3 mb-4">
            <div className="w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
              <span className="text-blue-600 text-sm font-medium">i</span>
            </div>

            <h3 className="text-base font-semibold text-slate-800 dark:text-white">
              Security Tips
            </h3>
          </div>

          <ul className="space-y-2 text-sm text-slate-600 dark:text-slate-400">
            <li>Use a strong, unique password</li>
            <li>Keep admin access limited to trusted staff</li>
            <li>Review moderation and verification queues regularly</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
