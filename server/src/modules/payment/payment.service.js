const axios = require("axios");

const CHAPA_SECRET_KEY = process.env.CHAPA_SECRET_KEY;
const CHAPA_BASE_URL = process.env.CHAPA_BASE_URL || "https://api.chapa.co/v1";
const handleStartLearning = async (courseId) => {
  try {
    const res = await fetch(`${API_BASE_URL}/api/payments/start`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${localStorage.getItem("token")}`,
      },
      body: JSON.stringify({ courseId }),
    });

    const data = await res.json();

    if (!res.ok) throw new Error(data.message);

    // redirect to chapa
    window.location.href = data.checkout_url;
  } catch (err) {
    alert(err.message);
  }
};
const initializePayment = async ({
  amount,
  email,
  firstName,
  lastName,
  courseId,
  userId,
}) => {
  try {
    if (!CHAPA_SECRET_KEY) {
      throw new Error("Missing CHAPA_SECRET_KEY");
    }

    if (!courseId) {
      throw new Error("courseId is required");
    }

    // SAFE tx_ref (max 50 chars rule fixed)
    const tx_ref = `crs_${Date.now()}_${Math.random()
      .toString(36)
      .substring(2, 8)}`;

    const payload = {
      amount: Number(amount),
      currency: "ETB",
      email,
      first_name: firstName,
      last_name: lastName,

      tx_ref,

      // SAFE description (ONLY allowed characters)
      description: "Course purchase",

      callback_url: `${process.env.FRONTEND_URL}/payment/callback`,
      return_url: `${process.env.FRONTEND_URL}/student/saved`,
    };

    const response = await axios.post(
      `${CHAPA_BASE_URL}/transaction/initialize`,
      payload,
      {
        headers: {
          Authorization: `Bearer ${CHAPA_SECRET_KEY}`,
          "Content-Type": "application/json",
        },
      },
    );

    if (!response.data?.data?.checkout_url) {
      throw new Error("Invalid Chapa response");
    }

    return {
      checkout_url: response.data.data.checkout_url,
      tx_ref,
    };
  } catch (error) {
    console.log("Chapa Init Error:", error.response?.data || error.message);

    throw new Error(
      error.response?.data?.message || "Failed to initialize payment",
    );
  }
};



const getMyPurchasedCourses = async (userId) => {
  return prisma.purchase.findMany({
    where: {
      userId,
      paid: true,
    },
    include: {
      course: {
        include: {
          expert: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
            },
          },
        },
      },
    },
    orderBy: {
      createdAt: "desc",
    },
  });
};

module.exports = {
  initializePayment,
  getMyPurchasedCourses,
};