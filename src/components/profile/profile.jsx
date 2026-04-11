import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";

export default function Profile() {
  const navigate = useNavigate();
  const { logout } = useAuth();

  const handleLogout = () => {
    logout();
    navigate("/signin");
  };

  return (
    <div className="min-h-screen bg-slate-100 dark:bg-slate-900 flex justify-center p-6">
      
      <div className="flex flex-col justify-between w-full max-w-md">
        
        {/* Profile Card */}
        <div className="flex justify-center items-center flex-grow">
          <div className="w-full bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
            
            {/* Profile Header */}
            <div className="flex flex-col items-center text-center">
              <img
                src="https://via.placeholder.com/120"
                alt="Profile"
                className="w-28 h-28 rounded-full ring-4 ring-blue-500 object-cover"
              />

              <h2 className="mt-4 text-xl font-semibold text-slate-800 dark:text-white">
                Admin Name
              </h2>
              <button
                onClick={() => navigate("/profile/edit-profile")}
                className="text-blue-500 text-sm mt-1 hover:underline"
              >
                Edit profile
              </button>

              
            </div>

            {/* Profile Info */}
            <div className="mt-6 space-y-3">
              <div className="flex justify-between border-b pb-2 border-slate-200 dark:border-slate-700">
                <span className="text-slate-600 dark:text-slate-400">Email</span>
                <span className="text-slate-800 dark:text-white">
                  admin@email.com
                </span>
              </div>

              <div className="flex justify-between border-b pb-2 border-slate-200 dark:border-slate-700">
                <span className="text-slate-600 dark:text-slate-400">Role</span>
                <span className="text-slate-800 dark:text-white">
                  Administrator
                </span>
              </div>

              <div className="flex justify-between border-b pb-2 border-slate-200 dark:border-slate-700">
                <span className="text-slate-600 dark:text-slate-400">Status</span>
                <span className="text-green-500 font-medium">Active</span>
              </div>

              {/* Add Admin Button */}
              <button
                onClick={() => navigate("/profile/add-admin")}
                className="mt-4 w-full bg-green-500 hover:bg-green-600 text-white py-2 rounded-lg transition"
              >
                Add New Admin
              </button>

              {/* Logout */}
              <button
                onClick={handleLogout}
                className="mt-2 w-full bg-red-500 hover:bg-red-600 text-white py-2 rounded-lg transition"
              >
                Logout
              </button>
            </div>
          </div>
        </div>

        {/* Security Tips */}
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
            <li>• Use a strong, unique password</li>
            <li>• Enable two-factor authentication</li>
            <li>• Never share your credentials</li>
          </ul>
        </div>

      </div>
    </div>
  );
}