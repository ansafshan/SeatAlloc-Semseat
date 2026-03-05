require("dotenv").config();
const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const db = require("./config/db");


const app = express();

// Middleware
app.use(cors());
app.use(express.json());


// Test route
app.get("/", (req, res) => {
  res.send("Backend is running!");
});

app.get("/api/status", (req, res) => {
  res.json({
    status: "ok",
    message: "API is working",
    time: new Date().toISOString(),
  });
});

app.post("/api/echo", (req, res) => {
  // Whatever JSON the client sends in the body, we send it back
  res.json({
    received: req.body,
    info: "This is what you sent to the server",
  });
});

app.post("/api/students", async (req, res) => {
  try {
    const {
      name,
      registrationNumber,
      email,
      department,
      semester,
      batch,
      status,
      malpracticeFlag,
    } = req.body;

    // ✅ Email NOT required anymore
    if (
      !name ||
      !registrationNumber ||
      !department ||
      !semester ||
      !batch
    ) {
      return res.status(400).json({
        error:
          "name, registrationNumber, department, semester, and batch are required",
      });
    }

    const reg = registrationNumber.toUpperCase();

    const defaultPassword =
      process.env.DEFAULT_STUDENT_PASSWORD || "cec@123";

    const passwordHash = await bcrypt.hash(defaultPassword, 10);

    // If email empty → store NULL
    const emailValue = email && email.trim() !== "" ? email : null;
    const formatName = (str) =>
      str
        .trim()
        .split(/\s+/)
        .map(w => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
        .join(" ");

    const formattedName = formatName(name);

    await db.execute(
      `INSERT INTO students
       (name, registration_number, email, password_hash,
        department, semester, batch, status, malpractice_flag)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        formattedName,
        reg,
        emailValue,
        passwordHash,
        department,
        semester,
        batch,
        status ?? "active",
        malpracticeFlag ?? false,
      ]
    );

    res.status(201).json({
      message: "Student created successfully",
      student: {
        name,
        registrationNumber: reg,
        email: emailValue,
        department,
        semester,
        batch,
        status: status ?? "active",
        malpracticeFlag: malpracticeFlag ?? false,
      },
    });
  } catch (err) {
    console.error("Error creating student (MySQL):", err.message);

    if (err.code === "ER_DUP_ENTRY") {
      return res.status(409).json({
        error:
          "A student with this registrationNumber or email already exists",
      });
    }

    res.status(500).json({
      error: "Internal server error",
    });
  }
});





app.get("/api/students", async (req, res) => {
  try {
    const [rows] = await db.execute(
      `SELECT
         id,
         name,
         registration_number,
         email,
         department,
         semester,
         batch,
         status,
         malpractice_flag,
         created_at,
         updated_at
       FROM students`
    );

    const students = rows.map((s) => ({
      id: s.id,
      name: s.name,
      registrationNumber: s.registration_number,
      email: s.email,
      department: s.department,
      semester: s.semester,
      batch: s.batch,
      status: s.status,
      malpracticeFlag: Boolean(s.malpractice_flag),
      createdAt: s.created_at,
      updatedAt: s.updated_at,
    }));

    res.json(students);
  } catch (err) {
    console.error("Fetch students error:", err.message);
    res.status(500).json({ error: "Internal server error" });
  }
});


//get student with reg no
app.get("/api/students/registration/:reg", async (req, res) => {
  try {
    const reg = req.params.reg.toUpperCase();

    const [rows] = await db.execute(
      `SELECT *
       FROM students
       WHERE registration_number = ?`,
      [reg]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "Student not found" });
    }

    const s = rows[0];

    res.json({
      name: s.name,
      registrationNumber: s.registration_number,
      email: s.email,
      department: s.department,
      semester: s.semester,
      batch: s.batch,
      status: s.status,
      malpracticeFlag: Boolean(s.malpractice_flag),
      createdAt: s.created_at,
      updatedAt: s.updated_at,
    });

  } catch (err) {
    console.error("Fetch by reg error:", err.message);
    res.status(500).json({ error: "Internal server error" });
  }
});


app.get("/api/students/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await db.execute(
      `SELECT *
       FROM students
       WHERE id = ?`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "Student not found" });
    }

    const s = rows[0];

    res.json({
      id: s.id,
      name: s.name,
      registrationNumber: s.registration_number,
      email: s.email,
      department: s.department,
      semester: s.semester,
      batch: s.batch,
      status: s.status,
      malpracticeFlag: Boolean(s.malpractice_flag),
      createdAt: s.created_at,
      updatedAt: s.updated_at,
    });

  } catch (err) {
    console.error("Fetch student error:", err.message);
    res.status(400).json({ error: "Invalid student ID" });
  }
});




// ✅ Student Login (registrationNumber + password)
app.post("/api/students/login", async (req, res) => {
  try {
    const { registrationNumber, password } = req.body;

    if (!registrationNumber || !password) {
      return res.status(400).json({
        error: "registrationNumber and password are required",
      });
    }

    const reg = registrationNumber.toUpperCase();

    // 🔹 Fetch student from MySQL
    const [rows] = await db.execute(
      `SELECT *
       FROM students
       WHERE registration_number = ?`,
      [reg]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        error: "Invalid registration number or password",
      });
    }

    const student = rows[0];

    // 🔒 Compare password
    const isMatch = await bcrypt.compare(password, student.password_hash);

    if (!isMatch) {
      return res.status(401).json({
        error: "Invalid registration number or password",
      });
    }

    // 🧹 Remove sensitive field before sending
    delete student.password_hash;

    res.json({
      message: "Login successful",
      mustChangePassword: Boolean(student.must_change_password),
      student: {
        name: student.name,
        registrationNumber: student.registration_number,
        email: student.email,
        department: student.department,
        semester: student.semester,
        batch: student.batch,
        status: student.status,
        malpracticeFlag: student.malpractice_flag,
        createdAt: student.created_at,
        updatedAt: student.updated_at,
      },
    });
  } catch (err) {
    console.error("Login error (MySQL):", err.message);
    res.status(500).json({
      error: "Internal server error",
    });
  }
});



// ✅ Student Change Password
app.post("/api/students/change-password", async (req, res) => {
  try {
    const { registrationNumber, oldPassword, newPassword } = req.body;

    if (!registrationNumber || !oldPassword || !newPassword) {
      return res.status(400).json({
        error:
          "registrationNumber, oldPassword, and newPassword are required",
      });
    }

    const reg = registrationNumber.toUpperCase();

    // 🔹 Fetch student from MySQL
    const [rows] = await db.execute(
      `SELECT password_hash
       FROM students
       WHERE registration_number = ?`,
      [reg]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        error: "Student not found",
      });
    }

    const student = rows[0];

    // 🔒 Verify old password
    const isMatch = await bcrypt.compare(
      oldPassword,
      student.password_hash
    );

    if (!isMatch) {
      return res.status(401).json({
        error: "Old password is incorrect",
      });
    }

    // 🔒 Hash new password
    const newPasswordHash = await bcrypt.hash(newPassword, 10);

    // 🔹 Update password + flag in MySQL
    await db.execute(
      `UPDATE students
       SET password_hash = ?, must_change_password = false
       WHERE registration_number = ?`,
      [newPasswordHash, reg]
    );

    res.json({
      message: "Password changed successfully",
      mustChangePassword: false,
    });
  } catch (err) {
    console.error("Change password error (MySQL):", err.message);
    res.status(500).json({
      error: "Internal server error",
    });
  }
});



//update student 
app.put("/api/students/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      registrationNumber,
      email,
      department,
      semester,
      batch,
      status,
      malpracticeFlag,
    } = req.body;

    const fields = [];
    const values = [];

    if (name !== undefined) {
      fields.push("name = ?");
      values.push(name);
    }

    if (registrationNumber !== undefined) {
      fields.push("registration_number = ?");
      values.push(registrationNumber.toUpperCase());
    }

    if (email !== undefined) {
      fields.push("email = ?");
      values.push(email);
    }

    if (department !== undefined) {
      fields.push("department = ?");
      values.push(department);
    }

    if (semester !== undefined) {
      fields.push("semester = ?");
      values.push(semester);
    }

    if (batch !== undefined) {
      fields.push("batch = ?");
      values.push(batch);
    }

    if (status !== undefined) {
      fields.push("status = ?");
      values.push(status);
    }

    if (malpracticeFlag !== undefined) {
      fields.push("malpractice_flag = ?");
      values.push(malpracticeFlag);
    }

    if (fields.length === 0) {
      return res.status(400).json({ error: "No fields to update" });
    }

    values.push(id);

    const [result] = await db.execute(
      `UPDATE students SET ${fields.join(", ")} WHERE id = ?`,
      values
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Student not found" });
    }

    res.json({ message: "Student updated successfully" });

  } catch (err) {
    console.error("Update error:", err.message);
    res.status(500).json({ error: "Internal server error" });
  }
});



//delete student
app.delete("/api/students/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await db.execute(
      `DELETE FROM students WHERE id = ?`,
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Student not found" });
    }

    res.json({ message: "Student deleted successfully" });

  } catch (err) {
    console.error("Delete error:", err.message);
    res.status(400).json({ error: "Invalid student ID" });
  }
});


// ✅ Invigilator Login
app.post("/api/invigilators/login", async (req, res) => {
  try {
    const { staffId, password } = req.body;

    if (!staffId || !password) {
      return res.status(400).json({
        error: "staffId and password are required",
      });
    }

    const staff = staffId.toUpperCase();

    // 🔹 Fetch invigilator
    const [rows] = await db.execute(
      `SELECT *
       FROM invigilators
       WHERE staff_id = ?`,
      [staff]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        error: "Invalid staff ID or password",
      });
    }

    const invigilator = rows[0];

    // 🔒 Compare password
    const isMatch = await bcrypt.compare(
      password,
      invigilator.password_hash
    );

    if (!isMatch) {
      return res.status(401).json({
        error: "Invalid staff ID or password",
      });
    }

    // remove password hash
    delete invigilator.password_hash;

    res.json({
      message: "Login successful",
      invigilator: {
        name: invigilator.name,
        staffId: invigilator.staff_id,
        email: invigilator.email,
        department: invigilator.department,
        phone: invigilator.phone,
        createdAt: invigilator.created_at,
      },
    });
//skdufgasuif
  } catch (err) {
    console.error("Invigilator login error:", err.message);
    res.status(500).json({
      error: "Internal server error",
    });
  }
});


// ✅ Register Invigilator
app.post("/api/invigilators", async (req, res) => {
  try {
    const {
      name,
      email,
      staffId,
      dob,
      department,
      phone
    } = req.body;

    if (!name || !staffId || !dob) {
      return res.status(400).json({
        error: "name, staffId and dob are required"
      });
    }

    const staff = staffId.toUpperCase();

    // extract birth year
    const birthYear = dob.split("-")[0];

    // generate default password
    const defaultPassword = `${staff}@${birthYear}`;

    // hash password
    const passwordHash = await bcrypt.hash(defaultPassword, 10);

    // insert into DB
    await db.execute(
      `INSERT INTO invigilators
       (name, email, staff_id, dob, password_hash, department, phone)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        name,
        email ?? null,
        staff,
        dob,
        passwordHash,
        department ?? null,
        phone ?? null
      ]
    );

    res.status(201).json({
      message: "Invigilator created successfully",
      invigilator: {
        name,
        staffId: staff,
        email,
        dob,
        department,
        phone
      }
    });

  } catch (err) {
    console.error("Create invigilator error:", err.message);

    if (err.code === "ER_DUP_ENTRY") {
      return res.status(409).json({
        error: "An invigilator with this staffId or email already exists"
      });
    }

    res.status(500).json({
      error: "Internal server error"
    });
  }
});



const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
