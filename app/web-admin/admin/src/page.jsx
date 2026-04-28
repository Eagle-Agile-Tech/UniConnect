import { BrowserRouter, Routes, Route } from "react-router-dom";

import Profile from "./components/profile/profile"; 
import EditProfile from "./components/profile/Editprofile";
import AddNewAdmin from "./components/profile/Addadmin";

export default function Pages() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Profile />} />
        <Route path="/edit-profile" element={<EditProfile />} />
        <Route path="/add-admin" element={<AddNewAdmin />} />
      </Routes>
    </BrowserRouter>
  );
}